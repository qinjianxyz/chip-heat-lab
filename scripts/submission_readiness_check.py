#!/usr/bin/env python3
"""Check public hackathon submission surfaces and report remaining blockers."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
REPO = "qinjianxyz/chip-heat-lab"
SITE = "https://chip-heat-lab.vercel.app"
RELEASE_TAG = "v0.1.0-hackathon-preview"
POWER_PROXY_COMMIT = "58c3fe72596158db9e973b8cbf6c8d60d3be0fd9"


def run(args: list[str], *, cwd: Path = ROOT) -> str:
    result = subprocess.run(
        args,
        cwd=cwd,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return result.stdout.strip()


def fetch_text(url: str) -> str:
    return run(["curl", "-fsSL", url])


def fetch_json(url: str) -> Any:
    return json.loads(fetch_text(url))


def ok(name: str, **details: Any) -> dict[str, Any]:
    return {"name": name, "status": "pass", **details}


def fail(name: str, reason: str, **details: Any) -> dict[str, Any]:
    return {"name": name, "status": "fail", "reason": reason, **details}


def git_state() -> dict[str, Any]:
    branch = run(["git", "branch", "--show-current"])
    head = run(["git", "rev-parse", "HEAD"])
    if branch != "main":
        return fail("git_state", f"expected main branch, got {branch}", branch=branch, head=head)
    status = run(["git", "status", "--short"])
    if status:
        return fail("git_state", "working tree is dirty", branch=branch, head=head, status=status)
    upstream = run(["git", "rev-parse", "@{upstream}"])
    if head != upstream:
        return fail("git_state", "HEAD does not match upstream", branch=branch, head=head, upstream=upstream)
    return ok("git_state", branch=branch, head=head)


def latest_main_ci(head: str) -> dict[str, Any]:
    payload = run(
        [
            "gh",
            "run",
            "list",
            "--repo",
            REPO,
            "--branch",
            "main",
            "--limit",
            "10",
            "--json",
            "conclusion,createdAt,databaseId,displayTitle,headSha,status,workflowName",
        ]
    )
    runs = json.loads(payload)
    for item in runs:
        if item.get("headSha") == head and item.get("workflowName") == "CI":
            if item.get("status") == "completed" and item.get("conclusion") == "success":
                return ok(
                    "latest_main_ci",
                    run_id=item.get("databaseId"),
                    title=item.get("displayTitle"),
                    created_at=item.get("createdAt"),
                )
            return fail("latest_main_ci", "CI for HEAD is not green", run=item)
    return fail("latest_main_ci", "no main CI run found for HEAD", head=head)


def branch_protection() -> dict[str, Any]:
    payload = run(["gh", "api", f"repos/{REPO}/branches/main/protection"])
    data = json.loads(payload)
    checks = data.get("required_status_checks") or {}
    contexts = set(checks.get("contexts") or [])
    force_push = ((data.get("allow_force_pushes") or {}).get("enabled")) is True
    deletion = ((data.get("allow_deletions") or {}).get("enabled")) is True
    strict = checks.get("strict") is True
    if "verify" not in contexts:
        return fail("branch_protection", "required verify check is missing", contexts=sorted(contexts))
    if not strict:
        return fail("branch_protection", "required checks are not strict")
    if force_push or deletion:
        return fail(
            "branch_protection",
            "main allows force push or deletion",
            allow_force_pushes=force_push,
            allow_deletions=deletion,
        )
    return ok("branch_protection", contexts=sorted(contexts), strict=strict)


def live_site() -> dict[str, Any]:
    homepage = fetch_text(f"{SITE}/")
    knowledge = fetch_text(f"{SITE}/knowledge")
    missing = []
    for needle in [
        "Chip Heat Lab",
        "Power Delivery Proxy",
        "Transient Review",
        "GitHub prerelease",
        "67.5",
        "41.4",
    ]:
        if needle not in homepage:
            missing.append(f"home:{needle}")
    for needle in ["Knowledge Base", "GBrain-ready knowledge system", "Power Delivery Proxy"]:
        if needle not in knowledge:
            missing.append(f"knowledge:{needle}")
    if missing:
        return fail("live_site", "live site is missing expected content", missing=missing)
    return ok("live_site", site=SITE)


def public_benchmarks() -> dict[str, Any]:
    value = fetch_json(f"{SITE}/benchmarks/value_loop/results.json")
    transient = fetch_json(f"{SITE}/benchmarks/transient_value_loop/results.json")
    power = fetch_json(f"{SITE}/benchmarks/power_delivery_proxy/results.json")
    failures = []
    if not value.get("pass"):
        failures.append("value_loop")
    if not transient.get("pass"):
        failures.append("transient_value_loop")
    if not power.get("pass"):
        failures.append("power_delivery_proxy")
    if failures:
        return fail("public_benchmarks", "one or more public benchmark gates failed", failures=failures)
    cases = power.get("cases", {})
    return ok(
        "public_benchmarks",
        value_peak_reduction_c=value["comparisons"]["kv_sram_floorplan_intervention"]["peak_reduction_c"],
        transient_top_intervention=transient["ranked_interventions"][0]["intervention"],
        power_nominal_droop_mv=cases["kv_clustered_nominal"]["worst_droop_mv"],
        power_dense_droop_mv=cases["kv_clustered_dense"]["worst_droop_mv"],
    )


def public_kb() -> dict[str, Any]:
    data = fetch_json(f"{SITE}/kb/kb_index.json")
    entries = data if isinstance(data, list) else data.get("entries") or []
    ids = {entry.get("id") for entry in entries}
    if len(entries) < 9:
        return fail("public_kb", "expected at least 9 KB entries", count=len(entries))
    if "demo-explanations/power-delivery-proxy" not in ids:
        return fail("public_kb", "power-delivery KB page is missing", count=len(entries))
    return ok("public_kb", count=len(entries))


def release_assets() -> dict[str, Any]:
    payload = run(
        [
            "gh",
            "release",
            "view",
            RELEASE_TAG,
            "--repo",
            REPO,
            "--json",
            "assets,body",
        ]
    )
    data = json.loads(payload)
    assets = {asset["name"] for asset in data.get("assets", [])}
    expected = {
        "ChipHeatLab-macos-unsigned-hackathon-preview.manifest.json",
        "ChipHeatLab-macos-unsigned-hackathon-preview.zip",
        "ChipHeatLab-macos-unsigned-hackathon-preview.zip.sha256",
    }
    missing = sorted(expected - assets)
    if missing:
        return fail("release_assets", "release is missing expected assets", missing=missing)
    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        run(
            [
                "gh",
                "release",
                "download",
                RELEASE_TAG,
                "--repo",
                REPO,
                "--pattern",
                "ChipHeatLab-macos-unsigned-hackathon-preview.manifest.json",
                "--dir",
                str(tmp_path),
                "--clobber",
            ]
        )
        manifest = json.loads((tmp_path / "ChipHeatLab-macos-unsigned-hackathon-preview.manifest.json").read_text())
    manifest_commit = str(manifest.get("git_commit"))
    run(["git", "merge-base", "--is-ancestor", manifest_commit, "HEAD"])
    run(["git", "merge-base", "--is-ancestor", POWER_PROXY_COMMIT, manifest_commit])
    if data.get("body", "").find(manifest_commit) < 0:
        return fail("release_assets", "release notes do not mention the manifest commit", manifest_commit=manifest_commit)
    return ok(
        "release_assets",
        tag=RELEASE_TAG,
        manifest_commit=manifest_commit,
        zip_bytes=manifest.get("zip_bytes"),
        signed=manifest.get("signed"),
        notarized=manifest.get("notarized"),
    )


def human_blockers(require_video: bool) -> dict[str, Any]:
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    submission = (ROOT / "docs/submission-copy.md").read_text(encoding="utf-8")
    blockers = []
    if "Demo video: pending recording." in readme or "Demo video: pending recording." in submission:
        blockers.append("demo video URL is still pending")
    if "Status: draft. Founder review is required" in submission:
        blockers.append("submission copy still needs founder review")
    status = "fail" if require_video and blockers else "pass"
    return {
        "name": "human_blockers",
        "status": status,
        "blockers": blockers,
        "require_video": require_video,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--require-video",
        action="store_true",
        help="fail if the README or submission copy still has the pending video placeholder",
    )
    parser.add_argument(
        "--public-only",
        action="store_true",
        help="skip clean-main local checkout checks and validate public surfaces against origin/main",
    )
    args = parser.parse_args()

    results: list[dict[str, Any]] = []
    exit_code = 0
    try:
        if args.public_only:
            head = run(["git", "rev-parse", "origin/main"])
            results.append(ok("git_state", mode="public-only", head=head))
        else:
            git = git_state()
            results.append(git)
            head = git.get("head") or run(["git", "rev-parse", "HEAD"])
        results.extend(
            [
                latest_main_ci(str(head)),
                branch_protection(),
                live_site(),
                public_benchmarks(),
                public_kb(),
                release_assets(),
                human_blockers(args.require_video),
            ]
        )
    except Exception as exc:  # noqa: BLE001 - this is a command-line checker.
        results.append(fail("submission_readiness_check", str(exc)))

    for item in results:
        if item.get("status") == "fail":
            exit_code = 1

    summary = {
        "technical_ready": all(
            item.get("status") == "pass" for item in results if item.get("name") != "human_blockers"
        ),
        "submission_ready": all(item.get("status") == "pass" for item in results)
        and not next((item.get("blockers") for item in results if item.get("name") == "human_blockers"), []),
        "results": results,
    }
    print(json.dumps(summary, indent=2, sort_keys=True))
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
