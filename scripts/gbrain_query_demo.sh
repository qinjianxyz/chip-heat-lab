#!/usr/bin/env bash
set -euo pipefail

if ! command -v gbrain >/dev/null 2>&1; then
  echo "gbrain CLI not found; run the queries manually in your configured GBrain client." >&2
  exit 2
fi

run_query() {
  local query="$1"
  python3 - "$query" <<'PY'
import subprocess
import sys

query = sys.argv[1]
print(f"\n## {query}")
try:
    result = subprocess.run(
        ["gbrain", "query", query, "--source", "chip-heat-lab"],
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=20,
    )
except subprocess.TimeoutExpired:
    print("GBrain query timed out after 20s; use kb_index.json as fallback.")
    raise SystemExit(124)

print(result.stdout.rstrip())
raise SystemExit(result.returncode)
PY
}

run_query "What assumptions does Chip Heat Lab make?"
run_query "What should I not claim from the heatmap?"
run_query "Why does spreading SRAM change the hotspot?"
run_query "How does the cooling preset affect the simplified model?"
run_query "What does the transient value-loop benchmark compare?"
run_query "What does the power-delivery proxy compare?"
