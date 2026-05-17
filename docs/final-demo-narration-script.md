# Final Demo Narration Script

Use this for the founder-recorded submission audio. The intended order is:

```text
browser design-review cockpit -> native macOS app -> knowledge / GStack close
```

## Recommended 90-Second Read

Chip Heat Lab is a simplified early-design thermal intuition demo for one
stylized accelerator floorplan. We built one end-to-end design-review workflow
around that floorplan.

The useful output is not just a heatmap. A hardware team wants to know what
failed, which intervention passed, what it cost, and which assumptions bound
the result. Here the clustered SRAM baseline fails simplified steady thermal,
transient dose, and power-delivery droop checks.

Rust ranks candidate interventions and recommends spread SRAM as the
lowest-cost passing fix in this model. That turns the result into a review
artifact: a visible field, explicit constraints, ranked options, and a claim
boundary.

The flagship app is native macOS SwiftUI. Swift owns the interface, but Rust
owns the backend computation through JSON. When we switch workload or
floorplan, the field and review metrics update from the same Rust CLI.

Different workload phases move the hotspot, including the IO-heavy path. The
review panel keeps the tradeoff framed as an action: constraints, ranked
interventions, warnings, and per-block maxima.

GBrain is represented by an importable markdown knowledge base: model
assumptions, citations, explanations, and claim boundaries are exported into
the app and site.

GStack kept the build narrow and shippable: scope lock, engineering review,
QA, ship checklist, and retro are committed.

End cap: Anvil Sim is the flagship project. Chip Heat Lab is the brand-new
public clean-room electronics-simulation slice we built for this hackathon:
benchmarks, explicit limits, and a path to richer geometry, more solver
families, validation ladders, evidence packs, and hardware-flow integrations.

## 60-Second Cut

Chip Heat Lab is a simplified early-design thermal intuition demo for one
stylized accelerator floorplan and one design-review question.

The baseline clustered SRAM case fails simplified steady thermal, transient
dose, and power-delivery droop checks. Rust recommends spread SRAM as the
lowest-cost passing fix.

The value is the decision packet: what failed, what passed, what it cost, and
what assumptions bound the result.

The native macOS app runs the same Rust backend through JSON. Toggling workload
and floorplan changes the field and review metrics.

GBrain is represented by an importable markdown knowledge base, and GStack
documents the build discipline: scope, review, QA, ship, and retro.

Anvil Sim is the flagship. Chip Heat Lab is the new public clean-room
electronics slice: benchmarks, explicit limits, and a roadmap to deeper solvers.

## Two-Minute Cut

Use `docs/final-demo-voiceover-120.txt` if the submission allows close to two
minutes. The three founder clips currently combine to about 95 seconds, so the
120-second cut is really the full cut with breathing room.
