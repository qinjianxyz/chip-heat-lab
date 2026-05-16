# Next Steps

Current state: foundation demo is public, tested, CI-backed, and has a
deterministic value-loop benchmark. The next work should focus on review,
packaging, recording, and deployment rather than expanding physics scope.

## P0 Before Submission

1. Deploy the `site/` directory to Vercel.
2. Record the 90-second demo video from the native app.
3. Include the value benchmark result in the submission copy.
4. Add the Vercel URL and video URL to `README.md`.
5. Do one visual polish pass after watching the recording.
6. Add a release zip for the unsigned local `dist/ChipHeatLab.app` bundle.

## P1 Polish

1. Add screenshots to the README and Vercel landing page.
2. Add a tiny `docs/gbrain-demo.md` receipt with real query output after
   running the import locally.
3. Add a release zip for the unsigned local app bundle.
4. Re-run `bash scripts/run_value_benchmark.sh` after any model/control change
   and commit the updated result if the output changes.

## Explicitly Out of Scope

- More physics models before the end-to-end value demo is recorded.
- FFI between Swift and Rust.
- RTL/OpenROAD integration.
- Production thermal-validation claims.
