# 06 Ship

## Ship Gate

Ship only after:

- Rust tests pass.
- CLI emits a valid result for the flagship scenario.
- `scripts/run_value_benchmark.sh` passes and writes
  `benchmarks/value_loop/results.json`.
- `kb_index.json` is generated.
- Non-claim lint passes.
- Next.js site builds.
- SwiftUI `RustRunner` points at a bundled CLI resource with an environment
  variable fallback for local development.

## Release Notes

This is a hackathon-ready demo with a deterministic value-loop benchmark. App
signing, archive export, and demo video capture are post-build packaging steps.
