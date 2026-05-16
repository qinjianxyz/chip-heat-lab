---
title: Design Review Workflow
type: explanation
claim_level: demo
sources:
  - docs/model.md
  - benchmarks/design_review/results.json
---

The design review workflow composes the demo's steady thermal, transient
thermal, and power-delivery proxy outputs into one ranked intervention table.
It turns the baseline KV-cache clustered-SRAM case into an inspectable review:
which simplified gates failed, which candidate fixes Rust compared, and why the
lowest-cost passing intervention is recommended for this demo model.

The baseline is a KV-cache-heavy clustered-SRAM floorplan with nominal cooling
and nominal power bumps. Candidate interventions change one or more design
knobs, then Rust checks simplified peak temperature, thermal dose, worst droop,
and a demo cost score.

For the checked-in benchmark, the baseline fails three simplified gates:

- steady KV peak above the demo limit;
- transient thermal dose above the demo limit;
- power-delivery droop proxy above the demo limit.

The ranked candidates are useful because they separate partial fixes from a
passing intervention. Workload staggering removes the transient dose but leaves
steady thermal and droop risk. Aggressive cooling lowers thermal metrics but
does not change the droop proxy. Dense power bumps lower droop but do not move
the thermal problem. Spread SRAM changes the shared spatial power map and is the
lowest-cost passing candidate in this benchmark.

The recommendation is not a final verification result. It is a transparent
early-design decision aid: which intervention should a reviewer inspect first,
which constraints caused the baseline to fail, and which assumption pages
explain the result in the simplified model?

Use this page when the app or demo needs to answer:

- "Why is the recommendation more than a heatmap?"
- "Which simplified constraints failed?"
- "Why did the ranking prefer layout movement over only cooling or only bumps?"
- "What must we avoid claiming from this benchmark?"
