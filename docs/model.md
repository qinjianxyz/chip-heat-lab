# Model

Chip Heat Lab has one locked demo model family. It is not a broad simulator; it
is a small design-review workflow over one stylized AI accelerator floorplan.
Rust owns each computed signal, and the app/site present those outputs as an
inspectable review artifact.

## Steady Thermal Model

The base model is a simplified 2D steady-state hotspot solve:

```text
-k * laplacian(T) + g_cool * (T - T_ambient) = q(x, y)
```

The implementation uses a fixed 96x96 grid. Each floorplan block contributes a
power-density value to the cells it covers. The solver computes temperature rise
above ambient with an iterative finite-difference update and then emits the
full temperature grid as JSON.

## Blocks

- MatMul Array A
- MatMul Array B
- SRAM / KV Cache
- NoC Spine
- SerDes / IO
- Control

## Controls

- Workload phase: balanced, training matmul, inference KV, or IO burst.
- Power scale: scalar applied to every block.
- Cooling preset: passive, airflow, or aggressive.
- Floorplan mode: clustered SRAM or spread SRAM.

## Interpretation

The output is useful for relative visual intuition in this demo: a phase change
can move the hotspot, stronger cooling can reduce peak temperature, and SRAM
placement can alter the visible thermal field. The numbers are deterministic for
the bundled scenario and should be treated as demo units tied to this model.

## Transient Extension

The Rust core also exposes a transient workload-trace mode:

```text
C * dU/dt = k * laplacian(U) - g_cool * U + q_phase(x, y, t)
T = T_ambient + U
```

Where `U` is temperature rise above ambient and `C` is a tunable demo thermal
capacitance. The transient mode reuses the same floorplan and power mapping but
steps through a workload trace: prefill burst, KV decode, IO flush, and decode
tail. It reports:

- max peak temperature;
- time above the demo risk threshold;
- thermal dose above that threshold;
- max spatial gradient;
- hotspot path distance;
- per-segment peak.

This makes the value loop closer to a design review: compare whether spreading
SRAM, stronger cooling, or workload staggering reduces risk in the same
simplified model.

## Power Delivery Proxy

The Rust core also exposes one adjacent power-delivery stress proxy:

```text
G_sheet * laplacian(D) + G_bump(x, y) * D = I(x, y)
```

Where `D` is a demo voltage-droop field in millivolts after scaling, `I(x, y)`
is the same block power map used by the thermal solver, `G_sheet` is a tunable
2D sheet conductance, and `G_bump(x, y)` is nonzero at idealized power bump
locations. The proxy reports:

- worst droop in millivolts;
- worst droop cell;
- per-block worst droop;
- thermal peak cell from the same scenario;
- distance and overlap score between thermal and droop hotspots.

This is useful for early workflow intuition because it shows that the same
floorplan and workload can create both a thermal concern and a power-delivery
stress proxy. The bump presets are intentionally simple: sparse, nominal, and
dense.

## Design Review Composition

The flagship workflow composes the three Rust-owned outputs into one ranked
review:

```text
candidate design
  -> steady KV thermal peak
  -> transient thermal dose over a workload trace
  -> power-delivery proxy worst droop
  -> constraint check + demo cost score
  -> ranked intervention recommendation
```

The default review compares:

- baseline clustered SRAM, nominal bumps, nominal cooling;
- spread SRAM;
- dense power bumps;
- aggressive cooling;
- workload staggering;
- combined spread-SRAM and dense-bump interventions.

The default constraints are intentionally simple demo gates:

- steady KV peak below `70 C`;
- transient thermal dose below `5 C-s`;
- worst droop below `55 mV`;
- overlap score below or equal to `1.0`.

This composition is useful because it moves the demo from "look at a heatmap"
to "which design change should I inspect first?" The review intentionally
includes single-knob candidates that solve only part of the problem:

- workload staggering can remove transient dose while leaving steady peak and
  droop proxy risk unchanged;
- aggressive cooling can reduce thermal metrics while leaving the droop proxy
  unchanged;
- dense power bumps can reduce the droop proxy while leaving thermal metrics
  unchanged;
- spreading SRAM changes the shared spatial power map and can improve all three
  simplified primary gates in this scenario.

The answer is still bounded by the non-claims: the ranking is deterministic and
inspectable, but it is not final verification, validation, package airflow, or a
physical PDN result.

## Knowledge And Process Binding

The model is paired with two repo-visible control systems:

- **GBrain-ready KB:** `kb/**/*.md` records assumptions, references, demo
  explanations, and claim boundaries. `scripts/generate_kb_index.py` turns those
  files into `kb_index.json` for the app and site, so explanations can be tied
  to source files instead of invented during the demo.
- **GStack artifacts:** `docs/gstack/` records the scope lock, engineering
  review, design review, QA plan, ship checklist, canary, and retro. The process
  artifact matters because it explains why the demo chose one ranked
  design-review workflow instead of chasing multiple unverified physics lanes.
