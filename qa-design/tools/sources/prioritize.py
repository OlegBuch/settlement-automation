# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6"]
# ///
"""Prioritizes the links found when walking Jira and Confluence from a root ticket or page.

Input: JSON built by the collect-sources skill while it walks the sources:
{
  "root": {"type": "jira", "id": "DEMO-1234"},
  "context": {"terms": ["catalog", "catalog-service", "/catalog-service/v1/registrations"]},
  "references": [
    {"id": "12345", "type": "confluence", "title": "5a. Catalog service contract",
     "origin": "jira-description", "depth": 1, "path": ["DEMO-1234", "12345"],
     "parent_level": null, "version": 44, "has_diagrams": true, "excerpt": "..."}
  ]
}

`origin` (how the link was found):
  jira-description, jira-ac, jira-remote-link, jira-issue-link:<type>, jira-comment, jira-epic, jira-parent,
  confluence-body, confluence-child, confluence-ancestor, confluence-comment,
  search-cql, search-jql, external

Levels (fixed rule: a search result never outranks a referenced link):
  P1 [60-100] explicitly referenced in the root (description, AC, remote links, implementation/test issue links,
               body of the root page)                                      -> always read
  P2 [30-59]  root comments, child pages, epic/parent, other issue links, or referenced in the body of a P1
                                                                           -> read while there is budget
  P3 [0-29]   depth >= 2 without a P1 parent, ancestors (indexes), loose attachments, unreferenced searches
                                                                           -> only suggested

Allowed spaces: Confluence pages whose `space` is outside CONFLUENCE_SPACES_FILTER (qa-design/config/atlassian.env)
get the action `out-of-space` and are never read. If `space` is not known yet, the page is treated as allowed
and the skill must confirm its space when reading it.

Usage:
  uv run qa-design/tools/sources/prioritize.py references.json [--budget 12] [--md]
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import yaml

QA_ROOT = Path(__file__).resolve().parents[2]  # qa-design/
ATLASSIAN_CONFIG = QA_ROOT / "config" / "atlassian.env"
TRUSTED_SOURCES = QA_ROOT / "knowledge" / "trusted-sources.yaml"
CARDS_DIR = QA_ROOT / "knowledge" / "features"

BANDS = {"P1": (60, 100), "P2": (30, 59), "P3": (0, 29)}
BASE = {"P1": 80, "P2": 45, "P3": 15}
ORIGIN_P1 = {"jira-description", "jira-ac", "jira-remote-link", "confluence-body"}
ORIGIN_P2 = {"jira-comment", "confluence-child", "jira-epic", "jira-parent", "confluence-comment"}
# Issue link types that imply a direct implementation or test relationship
STRONG_LINKS = ("test", "implement", "is tested by", "tests", "relates to story", "is caused by", "depends", "blocks", "is blocked by")
# Matches page titles, so the Spanish word "borrador" (draft) is kept on purpose
TITLE_PENALTY = re.compile(r"(?i)\[\s*wip\s*\]|\bwip\b|legacy|deprecated|obsolet|archiv|\bold\b|borrador|draft")


def allowed_spaces() -> set[str]:
    """Keys of CONFLUENCE_SPACES_FILTER; empty = no restriction. Reads only that line of the file."""
    if not ATLASSIAN_CONFIG.exists():
        return set()
    for line in ATLASSIAN_CONFIG.read_text(encoding="utf-8").splitlines():
        if line.startswith("CONFLUENCE_SPACES_FILTER="):
            return {e.strip() for e in line.split("=", 1)[1].split(",") if e.strip()}
    return set()


def _space_of(ref: dict) -> str | None:
    if ref.get("space"):
        return str(ref["space"])
    url = str(ref.get("url") or "")
    m = re.search(r"/(?:spaces|display)/([A-Za-z0-9_~-]+)", url)
    return m.group(1) if m else None


def _load_trusted() -> dict[str, str]:
    if not TRUSTED_SOURCES.exists():
        return {}
    data = yaml.safe_load(TRUSTED_SOURCES.read_text(encoding="utf-8")) or {}
    return {str(f["id"]): f.get("rating", "") for f in data.get("sources", []) if f.get("id")}


def _versions_in_memory() -> dict[str, int]:
    """page_id -> version already summarized in some knowledge/features card."""
    versions: dict[str, int] = {}
    for card in CARDS_DIR.glob("*.md") if CARDS_DIR.exists() else []:
        text = card.read_text(encoding="utf-8")
        if not text.startswith("---"):
            continue
        parts = text.split("---", 2)
        if len(parts) < 3:
            continue
        meta = yaml.safe_load(parts[1]) or {}
        for page in meta.get("confluence", []) or []:
            if page.get("id") and page.get("version"):
                versions[str(page["id"])] = max(int(page["version"]), versions.get(str(page["id"]), 0))
    return versions


def level(ref: dict) -> str:
    origin = str(ref.get("origin", ""))
    depth = int(ref.get("depth", 1))
    if origin.startswith("search") or origin in ("confluence-ancestor",):
        return "P3"
    if depth <= 1:
        if origin in ORIGIN_P1:
            return "P1"
        if origin.startswith("jira-issue-link"):
            link_type = origin.split(":", 1)[1].lower() if ":" in origin else ""
            return "P1" if any(t in link_type for t in STRONG_LINKS) else "P2"
        if origin in ORIGIN_P2:
            return "P2"
        return "P3"
    # depth 2: only rises to P2 if it comes from the body/description of a P1 link
    if depth == 2 and ref.get("parent_level") == "P1" and origin in ORIGIN_P1:
        return "P2"
    return "P3"


def score_ref(ref: dict, terms: list[str], trusted: dict[str, str], memory: dict[str, int]) -> dict:
    n = level(ref)
    score, reasons = BASE[n], []
    text = f"{ref.get('title', '')} {ref.get('excerpt', '')}".lower()
    matches = [t for t in terms if t and t.lower() in text]
    if matches:
        score += min(15, 5 * len(matches))
        reasons.append("mentions " + ", ".join(matches[:3]))
    if ref.get("has_diagrams"):
        score += 5
        reasons.append("has diagrams")
    rating = trusted.get(str(ref.get("id")))
    if rating == "useful":
        score += 10
        reasons.append("trusted source")
    elif rating == "not-useful":
        score -= 20
        reasons.append("marked as not useful")
    if TITLE_PENALTY.search(str(ref.get("title", ""))):
        score -= 15
        reasons.append("title is WIP/legacy/deprecated")
    action = None
    version = ref.get("version")
    if version and memory.get(str(ref.get("id"))) == int(version):
        action = "use-card"
        reasons.append(f"already summarized in memory (v{version})")
    low, high = BANDS[n]
    score = max(low, min(high, score))
    return {**ref, "level": n, "score": score, "reasons": reasons, "action": action}


def prioritize(payload: dict, budget: int, spaces: set[str] | None = None) -> list[dict]:
    terms = (payload.get("context") or {}).get("terms", [])
    trusted, memory = _load_trusted(), _versions_in_memory()
    spaces = allowed_spaces() if spaces is None else spaces

    # Deduplicate by (type, id): keep the best level and merge paths
    best: dict[tuple, dict] = {}
    for ref in payload.get("references", []):
        r = score_ref(ref, terms, trusted, memory)
        key = (r.get("type"), str(r.get("id")))
        current = best.get(key)
        if current is None or (r["level"], -r["score"]) < (current["level"], -current["score"]):
            paths = (current or {}).get("paths", [])
            best[key] = {**r, "paths": paths + [r.get("path")]}
        else:
            current["paths"].append(r.get("path"))

    ordered = sorted(best.values(), key=lambda r: (r["level"], -r["score"], str(r.get("id"))))
    read = 0
    for r in ordered:
        space = _space_of(r) if r.get("type") == "confluence" else None
        if space and spaces and space not in spaces:
            r["action"] = "out-of-space"
            r["reasons"].append(f"space {space} not allowed ({', '.join(sorted(spaces))})")
            continue
        if r["action"]:
            continue
        if r["level"] == "P1":
            r["action"] = "read"
            read += 1
        elif r["level"] == "P2" and read < budget:
            r["action"] = "read"
            read += 1
        else:
            r["action"] = "suggest"
    for i, r in enumerate(ordered, 1):
        r["src"] = f"SRC-{i:02d}"
    return ordered


def as_markdown(rows: list[dict]) -> str:
    out = ["| SRC | Level | Score | Action | Type | Source | Path | Reasons |", "|---|---|---|---|---|---|---|---|"]
    for r in rows:
        path = " → ".join(r["paths"][0] or []) if r.get("paths") and r["paths"][0] else ""
        version = f" v{r['version']}" if r.get("version") else ""
        out.append(f"| {r['src']} | {r['level']} | {r['score']} | {r['action']} | {r.get('type')} | `{r.get('id')}` {r.get('title', '')}{version} | {path} | {'; '.join(r['reasons'])} |")
    suggested = [r for r in rows if r["action"] == "suggest"]
    if suggested:
        out += ["", "### Suggested reads (confirm with the user)"]
        out += [f"- [ ] {r['src']} `{r.get('id')}` {r.get('title', '')} ({r['level']}, {r['score']})" for r in suggested]
    return "\n".join(out)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", help="JSON with root, context and references")
    parser.add_argument("--budget", type=int, default=12, help="maximum number of P1+P2 documents to read (P1 are always read)")
    parser.add_argument("--md", action="store_true")
    args = parser.parse_args()
    rows = prioritize(json.loads(Path(args.input).read_text(encoding="utf-8")), args.budget)
    print(as_markdown(rows) if args.md else json.dumps(rows, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
