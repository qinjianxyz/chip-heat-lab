#!/usr/bin/env python3
"""Reject overclaim phrases outside non-claim boundary files."""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN = [
    "signoff",
    "jedec",
    "foundry validation",
    "cfd",
    "package co-design",
    "reliability",
    "hotspot parity",
    "3d-ice",
    "commercial parity",
    "accurate chip thermal simulator",
]
SCAN_SUFFIXES = {".md", ".py", ".sh", ".rs", ".swift", ".tsx", ".ts", ".json"}
SKIP_PARTS = {
    ".git",
    "target",
    "node_modules",
    ".next",
    ".build",
}


def allowed(path: Path) -> bool:
    rel = path.relative_to(ROOT).as_posix().lower()
    if rel == "scripts/lint_nonclaims.py":
        return True
    if rel.endswith("kb_index.json"):
        return True
    return "non-claims" in rel or "non_claims" in rel or "non-claims" in rel


def should_scan(path: Path) -> bool:
    if path.name in {"package-lock.json", "Cargo.lock"}:
        return False
    if path.suffix.lower() not in SCAN_SUFFIXES:
        return False
    return not any(part in SKIP_PARTS for part in path.parts)


def main() -> int:
    failures: list[str] = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or not should_scan(path) or allowed(path):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore").lower()
        for phrase in FORBIDDEN:
            if phrase in text:
                failures.append(f"{path.relative_to(ROOT)}: forbidden phrase {phrase!r}")
    if failures:
        print("Forbidden overclaim phrases found outside non-claims files:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1
    print("non-claim lint passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
