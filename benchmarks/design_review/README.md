# Design Review Benchmark

This benchmark is the flagship value workflow for the hackathon demo.

The Rust CLI runs one simplified review of a stylized AI accelerator under a
KV-cache-heavy design question:

> Which lowest-cost intervention makes the design pass simplified thermal and
> power-delivery constraints?

The review composes three clean-room demo models:

- steady 2D thermal peak for the KV workload,
- transient thermal dose over a bursty workload trace,
- simplified power-delivery droop proxy over the same floorplan.

It then ranks interventions by pass/fail constraints and a documented demo cost
score. This is useful as an early-design decision aid because it turns field
outputs into an explicit recommendation. It is not final verification,
manufacturing validation, standards compliance, package airflow analysis, or a
physical PDN model.

The benchmark script is intentionally stricter than a snapshot exporter. It
runs the Rust CLI twice and fails if the canonical JSON changes, recomputes
every candidate's pass/fail state from the published constraints, verifies the
rank ordering, and checks that the recommendation is the lowest-cost passing
intervention. The site artifact is copied from the same validated JSON so the
public replay cannot drift from the repo benchmark.

Generate the benchmark:

```bash
bash scripts/run_design_review_benchmark.sh
```
