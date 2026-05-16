# Next Steps

Current state: the demo is public, tested, CI-backed, and has three bounded
Rust-owned proof surfaces: the steady value-loop benchmark, the transient
value-loop benchmark, and the power-delivery proxy benchmark. PR #9 merged the
power-delivery proxy on 2026-05-16, main CI passed, the Vercel site was
refreshed at <https://chip-heat-lab.vercel.app>, and the unsigned macOS preview
archive was refreshed on
<https://github.com/qinjianxyz/chip-heat-lab/releases/tag/v0.1.0-hackathon-preview>
from main commit `58c3fe72596158db9e973b8cbf6c8d60d3be0fd9`. Main branch
protection is active with strict `verify` status checks and force-push/deletion
disabled.

Scope lock: do not open another model lane before recording. The demo story is
now heat, transient workload memory, and one bounded power-delivery proxy over
the same stylized AI accelerator floorplan.

## P0 Before Submission

1. Record the final demo video from the native macOS app and public Vercel
   site.
2. Founder-review `docs/submission-copy.md` and paste the approved version into
   the submission form.
3. Add the demo video URL to `README.md`.
4. Do one visual polish pass after watching the recording.
5. Re-run native bundle QA immediately before recording:
   `bash scripts/bundle_macos_app.sh && open dist/ChipHeatLab.app`.
6. Re-run quiet public-surface checks immediately before submission:
   `bash scripts/visual_smoke_test.sh`,
   `python3 scripts/submission_readiness_check.py --require-video`, and
   `gh run list --repo qinjianxyz/chip-heat-lab --limit 5`.

## P1 Polish

1. Add screenshots to the README and Vercel landing page after the final video
   framing is chosen.
2. Add a tiny `docs/gbrain-demo.md` receipt with real query output after
   running the import locally.
3. Replace the unsigned local bundle with a signed/notarized artifact only if
   time permits; do not block the hackathon demo on notarization.
4. Re-run value, transient, and power-delivery benchmarks after any
   model/control change and commit the updated result if the output changes.

## Explicitly Out of Scope

- Broad multiphysics expansion before the end-to-end value demo is recorded.
- Additional chip physics dimensions before founder review of the recorded
  demo.
- FFI between Swift and Rust.
- RTL/OpenROAD integration.
- Production thermal-validation claims.
