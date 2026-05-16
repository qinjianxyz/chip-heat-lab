# 03 Engineering Review

## Architecture Lock

Rust owns the model and CLI output. SwiftUI and Next.js are renderers only.

## Interfaces

- Input: `ScenarioInput` JSON.
- Output: `SimulationResult` JSON.
- App boundary: `Process` stdin/stdout.
- Site boundary: exported JSON snapshots.

## Rejected Alternatives

- Browser-side solver: rejected so replay stays tied to exported Rust output.
- FFI app integration: rejected to keep bundling and debugging simple.
- Multi-scenario framework: rejected because the hackathon objective is one
  flagship demo.
