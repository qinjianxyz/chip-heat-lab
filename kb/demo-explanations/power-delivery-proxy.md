---
title: Power Delivery Proxy
type: explanation
claim_level: demo
sources:
  - docs/model.md
  - benchmarks/power_delivery_proxy/results.json
---

The power-delivery proxy adds one adjacent early-design check to the thermal
demo. Rust reuses the same floorplan and block-power map, places idealized
power bumps on a 2D resistive grid, and reports worst droop, per-block worst
droop, and the distance between thermal and droop hotspots. The benchmark
compares sparse, nominal, and dense bump presets plus clustered versus spread
SRAM.
