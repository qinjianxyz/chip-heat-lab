---
title: Transient Value Loop
type: explanation
claim_level: demo
sources:
  - docs/model.md
  - benchmarks/transient_value_loop/results.json
---

The transient value loop adds time to the demo. Instead of solving only one
static phase, Rust steps through a bursty workload trace and tracks peak
temperature, time above a demo threshold, thermal dose, spatial gradient, and
hotspot movement. The benchmark compares three interventions: spread SRAM,
stronger cooling, and workload staggering.
