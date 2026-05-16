#!/usr/bin/env python3
"""Generate a small JSON index from KB markdown frontmatter."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
KB_DIR = ROOT / "kb"
OUTPUTS = [
    ROOT / "kb_index.json",
    ROOT / "apps/macos/ChipHeatLab/Resources/kb_index.json",
    ROOT / "site/public/kb/kb_index.json",
]


def parse_markdown(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ValueError(f"{path} is missing frontmatter")
    _, frontmatter, body = text.split("---\n", 2)
    meta = parse_frontmatter(frontmatter, path)
    title = str(meta.get("title") or path.stem.replace("-", " ").title())
    summary = first_paragraph(body)
    return {
        "id": path.relative_to(KB_DIR).with_suffix("").as_posix(),
        "title": title,
        "path": path.relative_to(ROOT).as_posix(),
        "type": require(meta, "type", path),
        "claim_level": require(meta, "claim_level", path),
        "sources": meta.get("sources", []),
        "summary": summary,
    }


def parse_frontmatter(frontmatter: str, path: Path) -> dict[str, Any]:
    output: dict[str, Any] = {}
    lines = frontmatter.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        if ":" not in line:
            raise ValueError(f"invalid frontmatter line in {path}: {line}")
        key, raw = line.split(":", 1)
        key = key.strip()
        raw = raw.strip()
        if raw:
            output[key] = raw.strip('"')
            i += 1
            continue
        values: list[str] = []
        i += 1
        while i < len(lines) and lines[i].lstrip().startswith("- "):
            values.append(lines[i].split("- ", 1)[1].strip())
            i += 1
        output[key] = values
    return output


def require(meta: dict[str, Any], key: str, path: Path) -> Any:
    value = meta.get(key)
    if value in (None, "", []):
        raise ValueError(f"{path} missing required frontmatter key {key}")
    return value


def first_paragraph(body: str) -> str:
    paragraphs = [p.strip().replace("\n", " ") for p in body.split("\n\n") if p.strip()]
    if not paragraphs:
        return ""
    return paragraphs[0]


def main() -> int:
    entries = [parse_markdown(path) for path in sorted(KB_DIR.rglob("*.md"))]
    for output in OUTPUTS:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(entries, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"generated {len(entries)} KB entries")
    for output in OUTPUTS:
        print(output.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
