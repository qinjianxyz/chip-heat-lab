# Next Steps

Current state: the demo is public, tested, CI-backed, and has four bounded
Rust-owned proof surfaces: the steady value-loop benchmark, the transient
value-loop benchmark, the power-delivery proxy benchmark, and the composed
design-review benchmark. PR #9 merged the power-delivery proxy on 2026-05-16,
main CI passed, the Vercel site was refreshed at
<https://chip-heat-lab.vercel.app>, and the unsigned macOS preview archive was
refreshed on
<https://github.com/qinjianxyz/chip-heat-lab/releases/tag/v0.1.0-hackathon-preview>
from main commit `58c3fe72596158db9e973b8cbf6c8d60d3be0fd9`. Main branch
protection is active with strict `verify` status checks and force-push/deletion
disabled. A narrated fallback demo video is attached to the same prerelease at
<https://github.com/qinjianxyz/chip-heat-lab/releases/download/v0.1.0-hackathon-preview/chip-heat-lab-demo-narrated-fallback.mp4>.

Scope lock: do not open another physics/model lane before recording. The demo
story is now a design-review cockpit: steady thermal, transient workload
memory, and one bounded power-delivery proxy over the same stylized AI
accelerator floorplan, composed into a ranked recommendation.

The next build work should make that locked complexity visually obvious, not add
another solver. The first viewport should answer:

```text
What failed?
What did Rust compare?
What intervention passed?
What assumption/non-claim explains the result?
```

## P0 Before Submission

1. Founder-review `docs/founder-review-packet.md`, including the narrated
   fallback video. If the video is not good enough, record a live narrated
   replacement from the native macOS app and public Vercel site.
2. Founder-review `docs/submission-copy.md` and paste the approved version into
   the submission form.
3. Do one visual polish pass after watching the approved recording, with the
   first viewport centered on the design-review recommendation rather than an
   oversized standalone heatmap.
4. Re-run native bundle QA immediately before submission:
   `bash scripts/bundle_macos_app.sh && open dist/ChipHeatLab.app`.
5. Re-run quiet public-surface checks immediately before submission:
   `bash scripts/visual_smoke_test.sh`,
   `python3 scripts/submission_readiness_check.py --require-video`, and
   `gh run list --repo qinjianxyz/chip-heat-lab --limit 5`.
6. Confirm the design-review benchmark remains the lead story in README, Vercel,
   and the macOS app: baseline fails, ranked candidates compare tradeoffs, and
   the GBrain/GStack surfaces explain why the claim is bounded.

## P1 Polish

1. Add screenshots to the README and Vercel landing page after the final video
   framing is chosen.
2. Add a tiny `docs/gbrain-demo.md` receipt with real query output after
   running the import locally.
3. Replace the unsigned local bundle with a signed/notarized artifact only if
   time permits; do not block the hackathon demo on notarization.
4. Re-run value, transient, power-delivery, and design-review benchmarks after
   any model/control change and commit the updated result if the output
   changes.

## Explicitly Out of Scope

- Broad multiphysics expansion before the end-to-end value demo is recorded.
- Additional chip physics dimensions before founder review of the recorded
  demo.
- More 3D or animation work that does not expose a Rust-owned result.
- FFI between Swift and Rust.
- RTL/OpenROAD integration.
- Production thermal-validation claims.
