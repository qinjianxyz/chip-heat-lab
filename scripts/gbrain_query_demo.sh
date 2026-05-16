#!/usr/bin/env bash
set -euo pipefail

if ! command -v gbrain >/dev/null 2>&1; then
  echo "gbrain CLI not found; run the queries manually in your configured GBrain client." >&2
  exit 2
fi

gbrain query "What assumptions does Chip Heat Lab make?" --source chip-heat-lab
gbrain query "What should I not claim from the heatmap?" --source chip-heat-lab
gbrain query "Why does spreading SRAM change the hotspot?" --source chip-heat-lab
gbrain query "How does the cooling preset affect the simplified model?" --source chip-heat-lab
