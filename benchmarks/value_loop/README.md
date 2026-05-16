# Value-Loop Benchmark

## Design Question

For a KV-cache-heavy workload, does spreading the SRAM / KV Cache block change
hotspot and peak behavior before spending cooling budget?

This matters because the demo should show a full value loop: choose an
intervention, run the same Rust CLI model, compare the result, and explain the
tradeoff in plain language. It proves the demo can help reason about one early
layout question without expanding the physics scope.

## Cases

`scripts/run_value_benchmark.sh` runs the Rust CLI for four deterministic cases:

- KV workload with clustered SRAM.
- KV workload with spread SRAM.
- Training workload with airflow cooling.
- Training workload with aggressive cooling.

The benchmark writes `benchmarks/value_loop/results.json` and mirrors the same
JSON to `site/public/benchmarks/value_loop/results.json` for the Next.js site.
The site reads that file; it does not compute solver outputs.

## Metrics

- `peak_c`: peak temperature emitted by the Rust CLI.
- `hotspot_centroid`: center of the hottest region from the Rust result.
- `peak_reduction_c`: baseline peak minus intervention peak.
- `centroid_shift`: movement of the hotspot centroid in grid cells.
- `residual` and `iterations`: solver convergence receipts from the CLI.

## Pass Conditions

- Spread SRAM lowers the KV workload peak by more than `0.1 C` in this
  simplified model.
- Aggressive cooling lowers the training workload peak by more than `0.1 C`.
- Maximum residual across cases is below `1e-6`.
- No case reports warnings.

## Non-Claim

This is usefulness proof for a simplified early-design thermal intuition demo.
It is not physical validation, approval evidence, manufacturing evidence, or a
replacement for domain review.
