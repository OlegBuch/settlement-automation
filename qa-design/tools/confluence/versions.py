# /// script
# requires-python = ">=3.11"
# dependencies = ["httpx>=0.27", "pyyaml>=6"]
# ///
"""Detects Confluence pages that changed since a design used them.

Reads the `confluence:` frontmatter of qa-design/knowledge/features/*.md and compares each saved version with
the current one. Pages in a space outside CONFLUENCE_SPACES_FILTER are not queried.

Usage:
  uv run qa-design/tools/confluence/versions.py memory
  uv run qa-design/tools/confluence/versions.py memory --json
Exit code: 0 if everything is up to date, 3 if there are outdated pages.

Adapted from qa-harness tools/confluence/versions.py (memory scope only; no guide registry here).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from common.atlassian import QA_ROOT, REPO_ROOT, client, load_config  # noqa: E402


def _frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}
    parts = text.split("---", 2)
    return (yaml.safe_load(parts[1]) or {}) if len(parts) >= 3 else {}


def memory_pages() -> list[dict]:
    out = []
    for card in sorted((QA_ROOT / "knowledge" / "features").glob("*.md")):
        meta = _frontmatter(card)
        for page in meta.get("confluence", []) or []:
            if page.get("id") and str(page["id"]).strip("0"):
                out.append(
                    {
                        "source": card.relative_to(REPO_ROOT).as_posix(),
                        "page_id": str(page["id"]),
                        "title": page.get("title", ""),
                        "saved_version": page.get("version"),
                        "space": page.get("space"),
                        "feature_files": meta.get("feature_files", []),
                    }
                )
    return out


def compare(pages: list[dict]) -> list[dict]:
    allowed = {e.strip() for e in load_config().get("CONFLUENCE_SPACES_FILTER", "").split(",") if e.strip()}
    current: dict[str, dict] = {}
    outside = {p["page_id"] for p in pages if p.get("space") and allowed and p["space"] not in allowed}
    for pid in outside:
        current[pid] = {"out_of_space": True, "version": None}
    ids = sorted({p["page_id"] for p in pages} - outside)
    if ids:
        with client("confluence") as http:
            for page_id in ids:
                r = http.get(f"/rest/api/content/{page_id}", params={"expand": "version,space"})
                if r.status_code >= 400:
                    current[page_id] = {"error": f"HTTP {r.status_code}"}
                    continue
                data = r.json()
                current[page_id] = {
                    "version": data.get("version", {}).get("number"),
                    "date": data.get("version", {}).get("when"),
                    "author": (data.get("version", {}).get("by") or {}).get("displayName"),
                    "title": data.get("title"),
                }
    result = []
    for p in pages:
        now = current[p["page_id"]]
        if now.get("out_of_space"):
            status = "out-of-space"
        elif "error" in now:
            status = "error"
        elif p["saved_version"] in (None, ""):
            status = "no-saved-version"
        elif str(now["version"]) != str(p["saved_version"]):
            status = "outdated"
        else:
            status = "up-to-date"
        result.append({**p, "current": now, "status": status})
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("scope", choices=["memory"])
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    pages = memory_pages()
    if not pages:
        print("No Confluence pages recorded yet in qa-design/knowledge/features/.")
        return
    result = compare(pages)
    if args.json:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        for r in result:
            now = r["current"]
            detail = now.get("error") or ("not queried (space outside filter)" if now.get("out_of_space") else f"{r['saved_version']} -> {now['version']} ({now.get('date')}, {now.get('author') or '-'})")
            print(f"[{r['status']:>16}] {r['page_id']} {r['title'] or now.get('title', '')} | {detail} | {r['source']} | features: {', '.join(r['feature_files']) or '-'}")
    if any(r["status"] in ("outdated", "no-saved-version") for r in result):
        sys.exit(3)


if __name__ == "__main__":
    main()
