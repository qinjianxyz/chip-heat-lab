#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW_LABEL="${1:-hackathon-preview}"
LABEL="$(printf "%s" "${RAW_LABEL}" | tr -cs 'A-Za-z0-9._-' '-' | sed 's/^-//;s/-$//')"
if [[ -z "${LABEL}" ]]; then
  LABEL="hackathon-preview"
fi

DIST="${ROOT}/dist"
APP_NAME="ChipHeatLab"
APP="${DIST}/${APP_NAME}.app"
ZIP="${DIST}/${APP_NAME}-macos-unsigned-${LABEL}.zip"
SHA="${ZIP}.sha256"
MANIFEST="${DIST}/${APP_NAME}-macos-unsigned-${LABEL}.manifest.json"

cd "${ROOT}"
bash scripts/bundle_macos_app.sh

if [[ ! -d "${APP}" ]]; then
  echo "missing app bundle: ${APP}" >&2
  exit 1
fi

rm -f "${ZIP}" "${SHA}" "${MANIFEST}"
(cd "${DIST}" && ditto -c -k --keepParent "${APP_NAME}.app" "$(basename "${ZIP}")")

SHA256="$(shasum -a 256 "${ZIP}" | awk '{print $1}')"
printf "%s  %s\n" "${SHA256}" "$(basename "${ZIP}")" >"${SHA}"

ZIP_PATH="${ZIP}" MANIFEST_PATH="${MANIFEST}" SHA256="${SHA256}" LABEL="${LABEL}" python3 - <<'PY'
import json
import os
import subprocess
from datetime import datetime, timezone

zip_path = os.environ["ZIP_PATH"]
manifest_path = os.environ["MANIFEST_PATH"]
sha256 = os.environ["SHA256"]
label = os.environ["LABEL"]

def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()

manifest = {
    "name": "Chip Heat Lab macOS unsigned preview bundle",
    "label": label,
    "created_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "git_commit": git("rev-parse", "HEAD"),
    "git_branch": git("branch", "--show-current"),
    "zip": os.path.basename(zip_path),
    "zip_bytes": os.path.getsize(zip_path),
    "sha256": sha256,
    "bundle": "ChipHeatLab.app",
    "signed": False,
    "notarized": False,
    "intended_use": "Local hackathon review and demo recording only",
    "non_claim": "Unsigned packaging does not imply physical validation or production distribution.",
}

with open(manifest_path, "w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2)
    handle.write("\n")
PY

echo "Created ${ZIP}"
echo "Wrote ${SHA}"
echo "Wrote ${MANIFEST}"
