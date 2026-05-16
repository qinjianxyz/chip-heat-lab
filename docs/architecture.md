# Architecture

Chip Heat Lab has one execution path:

```text
ScenarioInput JSON -> Rust CLI -> SimulationResult JSON -> SwiftUI app and site replay
TransientScenarioInput JSON -> Rust CLI --transient -> TransientSimulationResult JSON -> benchmark/site
kb/*.md -> scripts/generate_kb_index.py -> app/site knowledge JSON
```

The Rust core owns the model, floorplan generation, and solver. The CLI is the
only runtime boundary exposed to the app. The macOS app launches the executable
with `Process`, sends JSON on stdin, reads JSON on stdout, and renders the
result. The public site does not solve; it reads snapshots exported from the
same CLI.

## Components

- `crates/chip_heat_core`: data contracts, 96x96 floorplan, power map, iterative
  finite-difference solve, transient workload trace solve, JSON schema
  generation, and tests.
- `crates/chip_heat_cli`: command-line JSON wrapper around the core.
- `apps/macos/ChipHeatLab`: SwiftUI shell with floorplan, heatmap, controls,
  peak readout, hotspot movement, per-block table, and explanation panel.
- `kb`: GBrain-importable assumptions, references, non-claims, and explanations.
- `site`: Vercel-ready Next.js pages backed by exported snapshots, benchmark
  results, and generated KB JSON.

## Data Contract

`ScenarioInput` contains the ambient temperature, conductivity, and four controls:
workload phase, power scale, cooling preset, and floorplan mode.

`SimulationResult` contains the temperature grid, peak, peak cell, hotspot
centroid, per-block maxima, residual, iteration count, warnings, controls, and
floorplan geometry.

`TransientScenarioInput` contains a workload trace, cooling preset, floorplan
mode, thermal capacitance, timestep, and risk threshold.

`TransientSimulationResult` contains sampled frames, the final temperature grid,
and risk metrics used by the transient value-loop benchmark.

`kb_index.json` contains normalized markdown frontmatter and summaries. The
macOS app uses it for the explanation panel, and the site uses it for the
knowledge page.

## Clean-Room Rule

The project is self-contained. Agents should not copy code, assets, solver
structure, proof formats, or project-specific names from private simulation
work elsewhere in the monorepo.
