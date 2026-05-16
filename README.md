# Chip Heat Lab

**Engineering simulation for chip design, shown as one simplified early-design thermal intuition demo.**

Chip Heat Lab is a clean-room OSS hackathon repo that demonstrates one stylized
AI accelerator floorplan. A Rust CLI solves a fixed 96x96 steady-state thermal
hotspot model, a macOS SwiftUI app runs that CLI through stdin/stdout JSON, and
a Next.js site replays exported solver snapshots. The project is intentionally
small: it helps a viewer build intuition about how workload, power, cooling, and
SRAM placement can move a hotspot in an early concept model.

## What You Can Demo In 90 Seconds

1. Open the macOS app and run the flagship floorplan.
2. Switch the workload phase to move the dominant block.
3. Toggle clustered versus spread SRAM to show hotspot and peak changes.
4. Increase cooling and watch the peak temperature drop.
5. Open the explanation panel and show the assumptions and non-claims.
6. Open the public site replay to show the same Rust-exported snapshots.

## Review Now

```bash
bash scripts/verify.sh
bash scripts/run_site_demo.sh
bash scripts/run_macos_demo.sh
```

- Site: `http://localhost:4177`
- Replay: `http://localhost:4177/replay`
- Native app: `scripts/run_macos_demo.sh` prepares the Rust binary and launches
  the SwiftUI app through Swift Package Manager.
- Double-click bundle: `scripts/bundle_macos_app.sh` writes
  `dist/ChipHeatLab.app` for local review. It is unsigned.

## Repository Layout

- `crates/chip_heat_core` - model types, floorplan generation, finite-difference
  solver, and tests.
- `crates/chip_heat_cli` - JSON stdin/file CLI wrapper around the core solver.
- `apps/macos/ChipHeatLab` - SwiftUI app package with a `RustRunner` process
  boundary and bundled resources.
- `site` - Vercel-ready Next.js public site and replay pages.
- `kb` - GBrain-importable markdown knowledge base.
- `scripts` - KB indexing, non-claim linting, snapshot export, and verification.
- `docs/gstack` - planning, review, QA, ship, canary, and retro artifacts.
- `docs/review-runbook.md` - exact local review flow for judges and teammates.
- `docs/next-steps.md` - current hackathon checklist after the foundation commit.

## Quick Start

```bash
cargo test --quiet
cargo run --quiet -p chip_heat_cli -- --input scenarios/flagship.json
bash scripts/run_value_benchmark.sh
python3 scripts/generate_kb_index.py
bash scripts/export_snapshots.sh
```

The CLI accepts a scenario JSON document via `--input <path>` or stdin and emits
a `SimulationResult` JSON payload with `temperature_grid`, `peak_c`,
`peak_cell`, `hotspot_centroid`, `per_block_max`, `residual`, `iterations`, and
`warnings`.

## Value Benchmark

The value-loop benchmark asks one practical demo question: for a KV-cache-heavy
workload, does spreading SRAM change hotspot and peak behavior before spending
cooling budget?

```bash
bash scripts/run_value_benchmark.sh
```

The script runs the Rust CLI for four cases and writes
`benchmarks/value_loop/results.json`. In the checked-in result, spread SRAM
reduces the KV workload peak from `71.085 C` to `68.236 C`, a `2.849 C`
reduction in this simplified model, while moving the hotspot centroid by
`15.052` grid cells. As a comparison control, aggressive cooling lowers the
training workload peak from `84.055 C` to `58.979 C`. This is usefulness proof
for the demo loop, not physical validation.

## Site

```bash
npm --prefix site install --silent
npm --prefix site run build --silent
npm --prefix site run dev -- --port 4177
```

The replay page reads JSON snapshots exported by the Rust CLI from
`site/public/snapshots/`; it does not reimplement the solver.

## macOS App

The SwiftUI package lives at `apps/macos/ChipHeatLab`. During local packaging,
copy the compiled Rust CLI into the app resources:

```bash
bash scripts/prepare_macos_resources.sh
cd apps/macos/ChipHeatLab
swift run ChipHeatLab
```

For a local double-click bundle:

```bash
bash scripts/bundle_macos_app.sh
open dist/ChipHeatLab.app
```

The generated bundle is unsigned. Signing/notarization is a release step, not a
simulation claim.

## Non-Claims

Chip Heat Lab is not a design verification tool. It is a deliberately simplified
early concept demo. The precise excluded categories are listed in
`docs/non-claims.md`, and the lint script blocks those phrases from general
project copy.
