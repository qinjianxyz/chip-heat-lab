# Chip Heat Lab

**Engineering simulation for chip design, shown as one simplified early-design thermal intuition demo.**

Chip Heat Lab is a clean-room OSS hackathon repo that demonstrates one stylized
AI accelerator floorplan. A Rust CLI solves fixed 96x96 steady and transient
thermal hotspot models, a macOS SwiftUI app runs the steady CLI path through
stdin/stdout JSON, and a Next.js site replays exported solver snapshots and
benchmark results. The project is intentionally small: it helps a viewer build
intuition about how workload, power, cooling, SRAM placement, burst scheduling,
and a simple power-delivery proxy can change early design risk in one concept
model.

## Links

- GitHub: <https://github.com/qinjianxyz/chip-heat-lab>
- Live site: <https://chip-heat-lab.vercel.app>
- Replay: <https://chip-heat-lab.vercel.app/replay>
- Knowledge base: <https://chip-heat-lab.vercel.app/knowledge>
- App release: <https://github.com/qinjianxyz/chip-heat-lab/releases/tag/v0.1.0-hackathon-preview>
- Demo video: pending recording.

## What You Can Demo In 90 Seconds

1. Open the macOS app and run the flagship floorplan.
2. Switch the workload phase to move the dominant block.
3. Toggle clustered versus spread SRAM to show hotspot and peak changes.
4. Increase cooling and watch the peak temperature drop.
5. Open the explanation panel and show the assumptions and non-claims.
6. Open the public site replay to show the same Rust-exported snapshots.
7. Show the transient and power-delivery proxy benchmarks on the site.
8. Open the knowledge page to show the GBrain-ready assumption system.

## Review Now

```bash
bash scripts/verify.sh
bash scripts/visual_smoke_test.sh
python3 scripts/submission_readiness_check.py
bash scripts/run_site_demo.sh
bash scripts/run_macos_demo.sh
```

- Site: `http://localhost:4177`
- Replay: `http://localhost:4177/replay`
- Knowledge: `http://localhost:4177/knowledge`
- Native app: `scripts/run_macos_demo.sh` prepares the Rust binary and launches
  the SwiftUI app through Swift Package Manager.
- Submission readiness: `scripts/submission_readiness_check.py` checks the
  public site, GitHub CI, branch protection, prerelease assets, public benchmark
  JSON, and remaining human blockers.
- Double-click bundle: `scripts/bundle_macos_app.sh` writes
  `dist/ChipHeatLab.app` for local review. It is unsigned.
- Release zip: `scripts/package_macos_release.sh hackathon-preview` writes a
  zipped unsigned app bundle plus checksum and manifest under `dist/`.

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
- `docs/submission-copy.md` - founder-review draft copy for the hackathon form.

## Quick Start

```bash
cargo test --quiet
cargo run --quiet -p chip_heat_cli -- --input scenarios/flagship.json
bash scripts/run_value_benchmark.sh
bash scripts/run_transient_value_benchmark.sh
bash scripts/run_power_delivery_benchmark.sh
python3 scripts/generate_kb_index.py
bash scripts/export_snapshots.sh
bash scripts/visual_smoke_test.sh
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

## Transient Value Benchmark

The transient value-loop benchmark asks a more realistic design-review question:
for a bursty AI accelerator workload trace, should we spend budget on spreading
SRAM, stronger cooling, or workload staggering?

```bash
bash scripts/run_transient_value_benchmark.sh
```

The script drives the Rust CLI in `--transient` mode and writes
`benchmarks/transient_value_loop/results.json`. In the checked-in result, the
baseline trace reaches `72.939 C`, spends `12.100 s` over the demo threshold,
and accumulates `13.189 C-s` of thermal dose. Stronger cooling is the top-ranked
intervention in this simplified model, while workload staggering removes the
same over-threshold dose without changing the floorplan or cooling preset.

## Power Delivery Proxy Benchmark

The power-delivery proxy benchmark asks one adjacent hardware question: for the
same floorplan and power map, do bump density and SRAM placement change the
simplified droop stress proxy?

```bash
bash scripts/run_power_delivery_benchmark.sh
```

The script drives the Rust CLI in `--power-proxy` mode and writes
`benchmarks/power_delivery_proxy/results.json`. In the checked-in result,
nominal KV clustered SRAM has `67.534 mV` worst droop, dense bumps reduce that
to `41.438 mV`, and spread SRAM with nominal bumps reduces it to `50.124 mV`.
The thermal/droop hotspot overlap score is `0.869` for the nominal clustered
case. This is usefulness proof for the demo loop, not a physical PDN model.

## Site

Live: <https://chip-heat-lab.vercel.app>

```bash
npm --prefix site install --silent
npm --prefix site run build --silent
npm --prefix site run dev -- --port 4177
```

The replay page reads JSON snapshots exported by the Rust CLI from
`site/public/snapshots/`; it does not reimplement the solver. The knowledge
page reads the generated KB index from `site/public/kb/kb_index.json`.

For quiet visual proof:

```bash
bash scripts/visual_smoke_test.sh
```

The script checks homepage, knowledge, and replay routes, then writes headless
screenshots under `dist/visual-proof/` when Chrome or Chromium is available.

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

For a local release archive:

```bash
bash scripts/package_macos_release.sh hackathon-preview
ls -lh dist/ChipHeatLab-macos-unsigned-hackathon-preview.zip
(cd dist && shasum -a 256 -c ChipHeatLab-macos-unsigned-hackathon-preview.zip.sha256)
cat dist/ChipHeatLab-macos-unsigned-hackathon-preview.zip.sha256
```

This archive is for hackathon review and demo recording. It is unsigned and
not notarized.

## Non-Claims

Chip Heat Lab is not a design verification tool. It is a deliberately simplified
early concept demo. The precise excluded categories are listed in
`docs/non-claims.md`, and the lint script blocks those phrases from general
project copy.
