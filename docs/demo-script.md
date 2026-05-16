# 90-Second Demo Script

## 0-15s: Open

"This is Chip Heat Lab, a simplified early-design thermal intuition demo for one
stylized AI accelerator floorplan."

Show the floorplan, heatmap, controls, and peak readout.

## 15-35s: Workload Moves The Hotspot

Switch from balanced to training matmul. Point to the hotspot movement arrow and
the peak cell shifting toward the matmul region.

## 35-55s: SRAM Layout Changes The Field

Switch from clustered SRAM to spread SRAM while keeping the inference KV phase.
Show the per-block table and the heatmap change.

## 55-70s: Cooling Lowers Peak

Switch cooling from passive or airflow to aggressive. Read the peak temperature
change.

## 70-82s: Benchmarks

Open the site. Show the transient ranking and the power-delivery proxy section:
dense bumps reduce the droop proxy, spread SRAM reduces it in the nominal bump
case, and the site is reading exported Rust benchmark JSON.

## 82-90s: Explainability

Open the explanation panel. Show assumptions and non-claims. Then open the site
knowledge page and note that it is reading the GBrain-ready markdown KB index.

## Recording Notes

- Build the Rust CLI before launching the app.
- Copy the CLI into `apps/macos/ChipHeatLab/Resources/bin/chip_heat_cli`.
- Generate `kb_index.json` before recording so the explanation panel has the
  same content as the site.
- For a silent 90-second visual dry run from captured stills, run
  `bash scripts/render_demo_video_draft.sh`. It writes
  `dist/demo-video/chip-heat-lab-demo-draft.mp4` and checks the duration. This
  is a storyboard aid, not the final narrated submission video.
- For a narrated local fallback using macOS text-to-speech, run
  `bash scripts/render_narrated_demo_video.sh`. It uses
  `docs/demo-voiceover.txt` and writes
  `dist/demo-video/chip-heat-lab-demo-narrated-fallback.mp4`. Founder review is
  still required before treating it as the submission video.
- Xcode signing and archive export are packaging steps after the working demo is
  verified locally.
