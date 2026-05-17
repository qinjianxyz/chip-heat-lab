# Clean-Room Notes

Chip Heat Lab is implemented from public, generic numerical ideas and local
requirements in this repo. The solver is a small finite-difference iteration for
one stylized floorplan and one visual demo.

This is a brand-new public electronics-simulation slice built for the hackathon.
Anvil Sim remains the broader flagship project, but Chip Heat Lab does not reuse
private Anvil Sim solvers, source, assets, benchmark formats, or architecture.

## Allowed Inputs

- The public task description for this hackathon repo.
- Generic finite-difference discretization knowledge.
- Code written directly in this project tree.
- Project-local docs, tests, and generated artifacts.

## Disallowed Inputs

- Private solver source from other projects.
- Private assets or demo scenes from other projects.
- Private architecture documents from other projects.
- Private proof, benchmark, or review formats from other projects.
- Reused product names or claim language from private projects.

## Review Checklist

- The SwiftUI app talks to the CLI through JSON, not linked private libraries.
- The site replay reads exported snapshots, not a copied solver.
- Public copy uses the narrow demo positioning.
- Public copy may mention Anvil Sim only as the broader flagship direction, and
  must keep Chip Heat Lab positioned as a new clean-room public module.
- Excluded claim phrases are confined to `docs/non-claims.md` and KB non-claim
  entries.
