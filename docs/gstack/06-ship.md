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
- The local macOS bundle opens a visible `Chip Heat Lab` window for recording.
- Native app runs do not leave stuck `chip_heat_cli` child processes after the
  Rust JSON exchange completes.
- `scripts/run_site_demo.sh` returns HTTP 200 for `/` and `/replay` in the local
  review environment.

## Release Notes

This is a hackathon-ready demo with a deterministic value-loop benchmark. App
signing, archive export, and demo video capture are post-build packaging steps.

## 2026-05-16 Commander QA

- PR #1, `test: add value-loop benchmark`, merged after CI and commander review.
- Commander QA found a local Next dev crash under Node 25 localStorage behavior
  and hardened `scripts/run_site_demo.sh`.
- Commander QA found the hand-built macOS bundle could launch without a visible
  window and hardened the app entry point for local recording.
- Commander QA found the Swift/Rust subprocess path could leave long-lived Rust
  CLI children and fixed the stdout drain order before waiting for process exit.
