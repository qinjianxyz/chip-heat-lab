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

## Quick Start

```bash
cargo test --quiet
cargo run --quiet -p chip_heat_cli -- --input scenarios/flagship.json
python3 scripts/generate_kb_index.py
bash scripts/export_snapshots.sh
```

The CLI accepts a scenario JSON document via `--input <path>` or stdin and emits
a `SimulationResult` JSON payload with `temperature_grid`, `peak_c`,
`peak_cell`, `hotspot_centroid`, `per_block_max`, `residual`, `iterations`, and
`warnings`.

## Site

```bash
npm --prefix site install --silent
npm --prefix site run build --silent
```

The replay page reads JSON snapshots exported by the Rust CLI from
`site/public/snapshots/`; it does not reimplement the solver.

## macOS App

The SwiftUI package lives at `apps/macos/ChipHeatLab`. During local packaging,
copy the compiled Rust CLI into the app resources:

```bash
cargo build --release -p chip_heat_cli
cp target/release/chip_heat_cli apps/macos/ChipHeatLab/Resources/bin/chip_heat_cli
python3 scripts/generate_kb_index.py
```

Then open `apps/macos/ChipHeatLab/Package.swift` in Xcode or run `swift build`
from that directory. Signing and a double-click `.app` archive are the remaining
packaging steps after the binary is copied.

## Non-Claims

Chip Heat Lab is not a design verification tool. It is a deliberately simplified
early concept demo. The precise excluded categories are listed in
`docs/non-claims.md`, and the lint script blocks those phrases from general
project copy.
