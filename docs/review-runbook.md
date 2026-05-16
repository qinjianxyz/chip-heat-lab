# Review Runbook

Use this when reviewing the current hackathon demo.

## 1. Verify the Project

```bash
bash scripts/verify.sh
```

Expected signal:

- Rust tests pass.
- The flagship CLI emits a result JSON with `peak_c`.
- KB index and replay snapshots are regenerated.
- Swift build succeeds on macOS.
- Non-claim lint passes.
- The Next.js site builds when dependencies are installed.

## 2. View the Web Replay

```bash
bash scripts/run_site_demo.sh
```

Open:

- `http://localhost:4177`
- `http://localhost:4177/replay`

The replay uses JSON snapshots exported by the Rust CLI. It does not run a
browser-side replacement solver.

## 3. View the Native macOS Demo

```bash
bash scripts/run_macos_demo.sh
```

The script prepares:

- `apps/macos/ChipHeatLab/Resources/bin/chip_heat_cli`
- `apps/macos/ChipHeatLab/Resources/kb_index.json`
- `apps/macos/ChipHeatLab/Resources/scenarios/flagship.json`

Then it launches the SwiftUI app with Swift Package Manager.

## 4. Build a Local App Bundle

```bash
bash scripts/bundle_macos_app.sh
open dist/ChipHeatLab.app
```

The bundle is unsigned and intended for local review/recording only.

## 5. Recording Checklist

1. Run the native app.
2. Show the default balanced heatmap.
3. Switch workload to move the hotspot.
4. Switch SRAM layout to show the floorplan effect.
5. Increase cooling to show monotonic peak reduction.
6. Show the explanation panel and non-claims.
7. Open the Vercel/local replay page.
