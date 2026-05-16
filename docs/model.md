# Model

Chip Heat Lab solves one simplified 2D steady-state hotspot model:

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
