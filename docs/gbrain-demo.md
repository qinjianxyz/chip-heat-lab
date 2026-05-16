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

Example queries to run during a demo:

- "What assumptions does Chip Heat Lab make?"
- "What should I not claim from the heatmap?"
- "Why does spreading SRAM change the hotspot?"
- "How does the cooling preset affect the simplified model?"
- "What does the value-loop benchmark prove?"
- "How much did spread SRAM change the KV workload peak?"
- "What is the benchmark's non-claim?"

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
