# Founder Review Packet

Status: awaiting founder decision. This packet exists so the remaining
hackathon submission gate is explicit, reviewable, and not confused with the
technical readiness checks.

## Decision Needed

Choose one:

- Approve the narrated fallback video and `docs/submission-copy.md` for the
  hackathon form.
- Request a new live narrated recording and list the requested changes.
- Request copy edits in `docs/submission-copy.md` before submission.

Do not mark the project submission-ready until this decision is made.

## Review Links

- Public repo: <https://github.com/qinjianxyz/chip-heat-lab>
- Live site: <https://chip-heat-lab.vercel.app>
- Replay: <https://chip-heat-lab.vercel.app/replay>
- Knowledge base: <https://chip-heat-lab.vercel.app/knowledge>
- App preview release:
  <https://github.com/qinjianxyz/chip-heat-lab/releases/tag/v0.1.0-hackathon-preview>
- Demo video candidate:
  <https://github.com/qinjianxyz/chip-heat-lab/releases/download/v0.1.0-hackathon-preview/chip-heat-lab-demo-narrated-fallback.mp4>

## Technical Readiness Snapshot

Latest verified state:

- Main commit: `3e211c2`
- Latest main CI: `docs: link demo video candidate (#14)` passed.
- `python3 scripts/submission_readiness_check.py` reports
  `technical_ready=true`.
- Release asset `chip-heat-lab-demo-narrated-fallback.mp4` is present and
  serves with `content-length: 2366738`.
- Live homepage contains the narrated fallback video link and founder approval
  caveat.

## Submission Copy

Use `docs/submission-copy.md` as the source of truth. The short description is:

> Chip Heat Lab is a clean-room open-source demo of engineering simulation for
> chip design: a Rust thermal solver, a bounded power-delivery proxy, a
> double-clickable SwiftUI app, and a Vercel replay that make early floorplan
> and workload tradeoffs visible.

Boundary sentence:

> Chip Heat Lab is a simplified early-design intuition demo for one stylized
> floorplan, with unit tests and deterministic benchmarks; it is not a
> production validation workflow.

## Approval Receipt

When approved, update `docs/submission-copy.md` from:

```text
Status: draft. Founder review is required before pasting this into a hackathon
submission form.
```

to:

```text
Status: founder-approved for hackathon submission on 2026-05-16.
```

Then run:

```bash
python3 scripts/submission_readiness_check.py --require-video
```

Expected result after approval: `submission_ready=true`.
