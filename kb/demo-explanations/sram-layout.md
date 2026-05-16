---
title: SRAM Layout Demo Explanation
type: demo_explanation
claim_level: demo
sources:
  - docs/demo-script.md
  - crates/chip_heat_core/src/lib.rs
---

Clustered SRAM concentrates one memory-heavy source in the lower-left middle of
the floorplan. Spread SRAM splits that source into two smaller regions, which
changes the heatmap and can lower or move the peak in the inference KV phase.
