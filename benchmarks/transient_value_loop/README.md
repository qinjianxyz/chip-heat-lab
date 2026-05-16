# Transient Value Loop Benchmark

This benchmark turns the demo from a single steady heatmap into a small design
review loop. It asks:

> For a bursty AI accelerator workload trace, which intervention lowers thermal
> risk: spreading SRAM, stronger cooling, or workload staggering?

The script runs the Rust CLI transient mode for four cases:

- `baseline_clustered`: clustered SRAM, airflow cooling, bursty workload trace.
- `spread_sram`: same workload and cooling with spread SRAM.
- `aggressive_cooling`: same workload and layout with stronger cooling.
- `staggered_workload`: same layout/cooling with a less concentrated workload
  schedule.

Run:

```bash
bash scripts/run_transient_value_benchmark.sh
```

The output lives in `benchmarks/transient_value_loop/results.json` and is copied
to `site/public/benchmarks/transient_value_loop/results.json`.

Interpretation is deliberately narrow: this is a deterministic usefulness
benchmark for the demo model, not a physical sign-off workflow.
