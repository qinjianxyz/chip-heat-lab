# GBrain Demo

The KB files under `kb/` are markdown documents with frontmatter for `type`,
`claim_level`, and `sources`. Generate the app/site index first:

```bash
python3 scripts/generate_kb_index.py
```

Then import or query with the local wrappers:

```bash
bash scripts/gbrain_import.sh
bash scripts/gbrain_query_demo.sh
```

## What GBrain Owns In The Demo

GBrain is not decorative in Chip Heat Lab. The repo keeps the explanation layer
as an importable knowledge base with explicit claim levels:

- `kb/assumptions/*` explains the simplified model knobs and data contracts.
- `kb/demo-explanations/*` explains why a specific benchmark or control changes
  the review result.
- `kb/non-claims/*` keeps the claim boundary visible when the demo is narrated.
- `kb/references/*` keeps source notes close to the app-facing explanations.

The app and site use the generated `kb_index.json` as their local fallback, so
the visible explanations remain source-backed even if the local GBrain service
is unavailable during the hackathon demo. The intended GBrain story is:
"the same markdown knowledge system can be imported, queried, and rendered in
the product surface."

## Design-Review Queries

Example queries to run during a demo:

- "What assumptions does Chip Heat Lab make?"
- "What should I not claim from the heatmap?"
- "Why does spreading SRAM change the hotspot?"
- "How does the cooling preset affect the simplified model?"
- "What does the value-loop benchmark prove?"
- "How much did spread SRAM change the KV workload peak?"
- "What is the benchmark's non-claim?"
- "What does the transient value-loop benchmark compare?"
- "Why does workload staggering reduce thermal risk in the demo?"
- "What does the power-delivery proxy compare?"
- "Do thermal and droop hotspots overlap in the benchmark?"
- "Why did the design review recommend spread SRAM?"
- "Which constraints did the baseline fail?"
- "How does the design-review benchmark use the GBrain KB?"
- "Why is aggressive cooling not the recommended first intervention?"
- "Why is dense power bumping not enough by itself?"

No transcript is included here because query output depends on the local GBrain
installation and should be captured only after the commands are actually run.

## Local Preflight Receipt

On 2026-05-16, `bash scripts/gbrain_query_demo.sh` ran locally but reported a
GBrain schema blocker:

```text
Schema probe/migrate failed: column "source_id" does not exist
Try: gbrain init --migrate-only
```

The wrapper also returned mostly `No results.` for the demo queries. Until the
local GBrain store is migrated and re-imported, use the markdown KB files and
generated `kb_index.json` as the benchmark explanation fallback.

Later on 2026-05-16, after adding the power-delivery proxy KB page, the same
wrapper started the first query but did not complete within the interactive
review window. The only emitted line was:

```text
[ai.gateway] recipe "google" declares an embedding touchpoint without max_batch_tokens; recursion is the only safety net for batch caps.
```

No successful transcript is recorded from that run. The source of truth remains
the markdown KB plus generated app/site index until local GBrain query health is
repaired.
