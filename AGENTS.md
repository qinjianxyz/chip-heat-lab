# Chip Heat Lab Agent Notes

Chip Heat Lab is a clean-room OSS hackathon demo. Treat it as a narrow flagship
experience, not a general simulator or product platform.

## Boundaries

- Keep all project truth inside this repository.
- Do not import private solver code, private assets, private architecture, or
  private project names from any other repository or local workspace.
- Use the phrase "simplified early-design thermal intuition demo" for the
  public positioning.
- Stronger excluded claim categories live in `docs/non-claims.md`; keep those
  phrases out of marketing and general docs so `scripts/lint_nonclaims.py`
  remains useful.
- The SwiftUI app calls the Rust executable with `Process` and JSON stdin/stdout.
  Do not add FFI for the demo.

## Verification

Run this from the project root before closeout:

```bash
bash scripts/verify.sh
```

For focused Rust work:

```bash
cargo test --quiet
cargo run --quiet -p chip_heat_cli -- --input scenarios/flagship.json
```

For site work, install dependencies in `site/` and run:

```bash
npm --prefix site run build --silent
```
