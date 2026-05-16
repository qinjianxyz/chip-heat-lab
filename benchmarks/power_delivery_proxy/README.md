# Power Delivery Proxy Benchmark

This benchmark adds one adjacent chip-design intuition layer to the thermal
demo. It asks:

> For the same AI accelerator floorplan and power map, do bump density and SRAM
> placement change the simplified power-delivery stress proxy?

The script runs the Rust CLI `--power-proxy` mode for five cases:

- `kv_clustered_sparse`: KV-cache workload, clustered SRAM, sparse idealized bumps.
- `kv_clustered_nominal`: same workload/layout with nominal bumps.
- `kv_clustered_dense`: same workload/layout with dense bumps.
- `kv_spread_nominal`: same workload and nominal bumps with spread SRAM.
- `training_nominal`: matmul-heavy workload with nominal bumps.

Run:

```bash
bash scripts/run_power_delivery_benchmark.sh
```

The output lives in `benchmarks/power_delivery_proxy/results.json` and is copied
to `site/public/benchmarks/power_delivery_proxy/results.json`.

Interpretation is deliberately narrow: this is a deterministic usefulness
benchmark for the demo model, not a physical PDN model.
