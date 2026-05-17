# Final Demo Edit Plan

Source clips are local recording artifacts outside the repo:

```text
<browser.mov>    # browser design-review cockpit, 27.45s
<native.mov>     # native macOS app, 53.74s
<knowledge.mov>  # GBrain/GStack/knowledge close, 14.34s
```

Use them in this order:

```text
browser value story -> native app proof -> GBrain/GStack/process close
```

## Segment Inventory

This is the map of what each source clip actually shows.

### `demo1.mov`: Browser Value Story, 27.45s

| Time | What is visible | Use |
| --- | --- | --- |
| 0-4s | Homepage hero and design-review cockpit: baseline fails 3 checks, spread SRAM recommendation, main deltas | Opening promise and business value |
| 4-11s | "Run a design review, not just a heatmap" and ranked candidate table | Explain usefulness: ranked decision artifact |
| 11-16s | Value benchmark and transient review sections | Show broader Rust proof surfaces beyond one static field |
| 16-21s | Power-delivery proxy section | Show adjacent hardware check: droop proxy and thermal/PDN overlap |
| 22-27s | Inspectable build system and submission surfaces | Use later for GStack/quiet proof/process close |

### `demo2.mov`: Native macOS App, 53.74s

| Time | What is visible | Use |
| --- | --- | --- |
| 0-2s | Native app starts on recommended KV inference + spread SRAM | Establish native app and Rust-backed default case |
| 2-10s | Training workload, cooling/floorplan changes, hotter MatMul field | Show interactive controls change the physical field |
| 10-16s | Return to KV inference + spread SRAM, SRAM hotspot visible | Show placement/workload relation to the design-review result |
| 18-28s | IO burst with SerDes/IO path heat and floorplan toggle | Show this is not a single pre-rendered picture |
| 30-38s | Review panel scroll: ranked interventions, warnings, per-block max | Show native app contains the decision packet, not only the heatmap |
| 40-48s | Question, GBrain-ready knowledge, assumptions, non-claims | Optional bridge into GBrain/claim-boundary close |
| 48-54s | Balanced/aggressive cooling return | Cut unless extra time remains |

### `demo3.mov`: GBrain Knowledge Close, 14.34s

| Time | What is visible | Use |
| --- | --- | --- |
| 0-2s | Knowledge base top: indexed KB pages, knowledge types, markdown source of truth | GBrain setup |
| 2-6s | Assumptions and demo explanations: cooling, SRAM layout, value loop | Assumption-backed explanation |
| 6-10s | Design-review workflow and power-delivery proxy KB cards | Tie KB to the exact demo workflow |
| 10-14s | Claim boundaries and reference card | Honest non-claim close |

## Recommended 90-Second Cut

This is the best hackathon submission length if the form allows it. It uses
the best business segment from the browser clip, three high-signal native app
segments, the GBrain knowledge close, and the GStack/process browser card.

| Time | Clip | Visual | Voiceover |
| --- | --- | --- | --- |
| 0-22s | `demo1.mov` 0-22s | Browser cockpit, ranked design review, value/transient/power proxy sections | "Chip Heat Lab is a simplified early-design thermal intuition demo for one stylized accelerator floorplan. The useful output is not just a heatmap: it tells a hardware team what failed, which intervention passed, what it cost, and which assumptions bound the result." |
| 22-38s | `demo2.mov` 0-16s | Native app toggles training/KV and floorplan/cooling | "The flagship app is native macOS SwiftUI. Swift owns the interface, but Rust owns the backend computation through JSON. Changing workload and floorplan changes the field from the same Rust CLI." |
| 38-48s | `demo2.mov` 18-28s | IO burst / SerDes heat path | "This is not a single pre-rendered picture: different workload phases move the hotspot and expose different design risks." |
| 48-60s | `demo2.mov` 30-42s | Native ranked interventions, warnings, per-block table | "The native review panel keeps the result framed as an engineering tradeoff: constraints, ranked interventions, warnings, and per-block maxima." |
| 60-68s | `demo2.mov` 40-48s | Native assumptions and non-claims panel | "The app also keeps the assumptions and non-claims visible beside the field." |
| 68-82s | `demo3.mov` 0-14s | Knowledge base, assumptions, design-review workflow, claim boundaries | "GBrain is the assumption system: markdown pages for model assumptions, citations, explanations, and claim boundaries are exported into the app and site." |
| 82-88s | `demo1.mov` 22-28s | Inspectable build system / GStack artifacts | "GStack kept the build narrow and shippable: scope lock, engineering review, QA, ship checklist, and retro are committed." |

## Tight 60-Second Cut

Use this if the submission limit is strict. It trims the native app clip hardest
but keeps the complete story. The current smart render is about `56s`, which
leaves a few seconds of buffer for a title card or upload trimming.

| Time | Clip | Visual | Voiceover |
| --- | --- | --- | --- |
| 0-16s | `demo1.mov` 0-16s | Browser cockpit, design review, value/transient sections | "Chip Heat Lab is a simplified early-design thermal intuition demo for one stylized accelerator floorplan. The baseline clustered SRAM case fails simplified steady thermal, transient dose, and power-delivery droop checks. Rust recommends spread SRAM as the lowest-cost passing fix." |
| 16-30s | `demo2.mov` 0-14s | Native app starts, training/KV controls, field changes | "The native macOS app runs the same Rust backend through JSON. Toggling workload and floorplan changes the field and review metrics." |
| 30-38s | `demo2.mov` 18-26s | IO burst / SerDes heat path | "A different workload phase moves heat toward IO, so the demo is interactive, not a pre-rendered heatmap." |
| 38-44s | `demo2.mov` 30-36s | Ranked interventions in native review panel | "The result stays framed as a decision packet: constraints, ranked interventions, and warnings." |
| 44-54s | `demo3.mov` 0-10s | Knowledge page and design-review workflow KB cards | "GBrain is the assumption system: model pages, references, explanations, and claim boundaries feed the app and site." |
| 54-58s | `demo1.mov` 22-26s | Inspectable build system | "GStack documents the build discipline: scope, review, QA, ship, and retro." |

## Full 95-Second Cut

Use this if the submission allows up to two minutes. The three source clips are
only about `95s` total, so this is the best "show everything coherent" cut while
staying well under `120s`.

Render:

```bash
bash scripts/stitch_founder_demo.sh 120 <browser.mov> <native.mov> <knowledge.mov>
```

Output:

```text
dist/demo-video/chip-heat-lab-founder-demo-120s.mp4
```

Standalone narration file: `docs/final-demo-voiceover-120.txt`.

Pacing:

1. Browser: explain what the workflow is and why the design-review framing is
   valuable.
2. Native: explain Rust/Swift ownership, toggle behavior, and the hotspot /
   ranked-intervention loop.
3. Knowledge/process: explain GBrain, GStack, and claim boundaries.

## Best One-Minute Voiceover

Standalone narration file: `docs/final-demo-voiceover-60.txt`.

> Chip Heat Lab is a simplified early-design thermal intuition demo for one
> stylized accelerator floorplan and one design-review question.
>
> The baseline clustered SRAM case fails simplified steady thermal, transient
> dose, and power-delivery droop checks. Rust ranks interventions and recommends
> spread SRAM as the lowest-cost passing fix in this model.
>
> The value is the decision packet: what failed, what passed, what it cost, and
> what assumptions bound the result.
>
> The native macOS app runs the same Rust backend through JSON. Toggling
> workload and floorplan changes the field and review metrics, so the demo is
> interactive, not a pre-rendered heatmap.
>
> GBrain is the assumption system: model pages, references, explanations, and
> non-claims are importable markdown and feed the app and site index.
>
> GStack is the build discipline: scope, review, QA, ship, and retro are
> committed. This is not production approval. It is the smallest honest wedge:
> one design, three checks, ranked interventions, native demo, web replay, and
> explicit assumptions.

## Best 90-Second Voiceover

Standalone narration file: `docs/final-demo-voiceover-90.txt`.

> Chip Heat Lab is a clean-room open-source demo of engineering simulation for
> chip design. We built one end-to-end design-review workflow for a stylized AI
> accelerator floorplan.
>
> The useful output is not just a heatmap. A hardware team wants to know what
> failed, which intervention passed, what it cost, and which assumptions bound
> the result. Here the clustered SRAM baseline fails simplified steady thermal,
> transient dose, and power-delivery droop checks.
>
> Rust ranks candidate interventions and recommends spread SRAM as the
> lowest-cost passing fix in this model. That turns the result into a review
> artifact: a visible field, explicit constraints, ranked options, and a claim
> boundary.
>
> The flagship app is native macOS SwiftUI. Swift owns the interface, but Rust
> owns the backend computation through JSON. When we switch workload or
> floorplan, the field and review metrics update from the same Rust CLI.
>
> This is the engineering moment: placement and workload move the hotspot, and
> the review panel keeps the tradeoff framed as an action.
>
> GBrain is used as an assumption system: markdown knowledge pages for model
> assumptions, citations, explanations, and non-claims are exported into the app
> and site.
>
> GStack kept the build narrow and shippable: scope lock, engineering review,
> QA, ship checklist, and retro are committed. This public repo is the smallest
> honest wedge for a future production system that could go deeper with richer
> geometry, more solver families, validation ladders, evidence packs, and
> hardware-flow integrations.

## Edit Notes

- Keep `demo1.mov` first. It explains the value before showing controls.
- Keep at least one native toggle from `demo2.mov`; otherwise the app looks
  static.
- For the native proof, prefer `demo2` 0-16s, 18-28s, and 30-42s. Those are the
  high-signal spans.
- Keep `demo3.mov` short but present. GBrain/GStack should feel like proof
  infrastructure, not an afterthought.
- Avoid production-approval language. Say "simplified", "bounded",
  "clean-room", and "early design review".
- If the final cut feels long, cut from the middle of the native app segment
  before cutting the browser opening or GBrain/GStack close.
