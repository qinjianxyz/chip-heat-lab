# Next Steps

Current state: foundation demo is public, tested, CI-backed, and has a
deterministic value-loop benchmark. PR #1 merged the benchmark on 2026-05-16.
Commander QA also found and fixed two demo-readiness issues: the local Next dev
server now handles Node 25 localStorage behavior, and the local macOS bundle
launch path opens a visible app window without leaking Rust CLI child
processes. The Vercel site is deployed at <https://chip-heat-lab.vercel.app>.
The unsigned macOS preview archive is attached to
<https://github.com/qinjianxyz/chip-heat-lab/releases/tag/v0.1.0-hackathon-preview>.
The next work should merge and redeploy the transient value-loop and knowledge
page upgrade, then decide whether one adjacent power-delivery proxy is worth
adding before recording.

## P0 Before Submission

1. Record the final demo video after the transient value-loop upgrade is merged
   and redeployed.
2. Founder-review `docs/submission-copy.md` and paste the approved version into
   the submission form.
3. Add the demo video URL to `README.md`.
4. Do one visual polish pass after watching the recording.
5. Re-run native bundle QA immediately before recording:
   `bash scripts/bundle_macos_app.sh && open dist/ChipHeatLab.app`.

## P1 Polish

1. Add screenshots to the README and Vercel landing page.
2. Add one bounded power-delivery proxy only if the current value demo is
   already green: use the same floorplan/power map, compute a simplified
   IR-drop stress map in Rust, and show whether droop hotspots overlap thermal
   hotspots. Do not add a second broad product lane.
3. Add a tiny `docs/gbrain-demo.md` receipt with real query output after
   running the import locally.
4. Replace the unsigned local bundle with a signed/notarized artifact only if
   time permits; do not block the hackathon demo on notarization.
5. Re-run value and transient benchmarks after any model/control change and
   commit the updated result if the output changes.

## Explicitly Out of Scope

- Broad multiphysics expansion before the end-to-end value demo is recorded.
- FFI between Swift and Rust.
- RTL/OpenROAD integration.
- Production thermal-validation claims.
