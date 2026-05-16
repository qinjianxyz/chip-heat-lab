---
title: Steady-State Equation Reference
type: reference
claim_level: educational
sources:
  - docs/model.md
---

The demo equation is `-k * laplacian(T) + g_cool * (T - T_ambient) = q(x, y)`.
The implementation solves for temperature rise above ambient with a small
finite-difference iteration.
