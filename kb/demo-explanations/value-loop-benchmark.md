---
title: Value-Loop Benchmark Explanation
type: demo_explanation
claim_level: demo
sources:
  - benchmarks/value_loop/README.md
  - benchmarks/value_loop/results.json
  - scripts/run_value_benchmark.sh
---

The value-loop benchmark asks whether spreading SRAM changes hotspot and peak
behavior for a KV-cache-heavy workload before spending cooling budget. It runs
the Rust CLI for clustered SRAM, spread SRAM, training with airflow, and
training with aggressive cooling, then aggregates the emitted JSON.

In the checked-in result, spread SRAM lowers the KV workload peak by `2.849 C`
and moves the hotspot centroid by `15.052` grid cells in this simplified model.
Aggressive cooling lowers the training peak by `25.076 C`. Treat this as demo
usefulness proof, not physical validation.
