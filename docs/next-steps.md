# Next Steps

Current state: foundation demo is public, tested, and CI-backed. The next work
should focus on review, packaging, and recording rather than expanding physics
scope.

## P0 Before Submission

1. Deploy the `site/` directory to Vercel.
2. Record the 90-second demo video from the native app.
3. Add the Vercel URL and video URL to `README.md`.
4. Build `dist/ChipHeatLab.app` and confirm it opens locally.
5. Do one visual polish pass after watching the recording.

## P1 Polish

1. Add screenshots to the README and Vercel landing page.
2. Add a tiny `docs/gbrain-demo.md` receipt with real query output after
   running the import locally.
3. Add a release zip for the unsigned local app bundle.
4. Add one more replay snapshot that isolates the SRAM layout comparison.

## Explicitly Out of Scope

- More physics models.
- FFI between Swift and Rust.
- RTL/OpenROAD integration.
- Production thermal-validation claims.
