# Architecture

Chip Heat Lab has one execution path:

```text
ScenarioInput JSON -> Rust CLI -> SimulationResult JSON -> SwiftUI app and site replay
```

The Rust core owns the model, floorplan generation, and solver. The CLI is the
only runtime boundary exposed to the app. The macOS app launches the executable
with `Process`, sends JSON on stdin, reads JSON on stdout, and renders the
result. The public site does not solve; it reads snapshots exported from the
same CLI.

## Components

- `crates/chip_heat_core`: data contracts, 96x96 floorplan, power map, iterative
  finite-difference solve, JSON schema generation, and tests.
- `crates/chip_heat_cli`: command-line JSON wrapper around the core.
- `apps/macos/ChipHeatLab`: SwiftUI shell with floorplan, heatmap, controls,
  peak readout, hotspot movement, per-block table, and explanation panel.
- `kb`: GBrain-importable assumptions, references, non-claims, and explanations.
- `site`: Vercel-ready Next.js pages backed by exported snapshots.

## Data Contract

`ScenarioInput` contains the ambient temperature, conductivity, and four controls:
workload phase, power scale, cooling preset, and floorplan mode.

`SimulationResult` contains the temperature grid, peak, peak cell, hotspot
centroid, per-block maxima, residual, iteration count, warnings, controls, and
floorplan geometry.

## Clean-Room Rule

The project is self-contained. Agents should not copy code, assets, solver
structure, proof formats, or project-specific names from private simulation
work elsewhere in the monorepo.
