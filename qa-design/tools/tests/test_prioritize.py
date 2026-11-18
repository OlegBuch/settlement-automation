"""Prioritization of a synthetic source graph."""

import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "sources"))
import prioritize  # noqa: E402

ENTRADA = {
    "root": {"type": "jira", "id": "DEMO-1234"},
    "context": {"terms": ["catalog", "catalog-service", "queue"]},
    "references": [
        {"id": "12345", "type": "confluence", "title": "5a. Catalog service contract", "origin": "jira-description", "depth": 1, "path": ["DEMO-1234", "12345"], "version": 44, "has_diagrams": True, "excerpt": "catalog persistence and queue output"},
        {"id": "DEMO-1233", "type": "jira", "title": "Create catalog records", "origin": "jira-issue-link:is tested by", "depth": 1, "path": ["DEMO-1234", "DEMO-1233"]},
        {"id": "DEMO-2000", "type": "jira", "title": "Catalog event processing", "origin": "jira-epic", "depth": 1, "path": ["DEMO-1234", "DEMO-2000"]},
        {"id": "12346", "type": "confluence", "title": "Catalog component", "origin": "confluence-body", "depth": 2, "parent_level": "P1", "path": ["DEMO-1234", "12345", "12346"], "version": 66},
        {"id": "12347", "type": "confluence", "title": "Catalog overview", "origin": "confluence-ancestor", "depth": 2, "path": ["DEMO-1234", "12345", "12347"], "version": 2},
        {"id": "12348", "type": "confluence", "title": "7e. POST Endpoints - Catalog [WIP]", "origin": "confluence-body", "depth": 3, "path": ["DEMO-1234", "12345", "12346", "12348"], "version": 4},
        {"id": "12349", "type": "confluence", "title": "3b. Catalog sync process", "origin": "search-cql", "depth": 1, "path": ["CQL: catalog-service registrations"], "version": 58, "has_diagrams": True, "excerpt": "catalog-service registration data"},
        # Duplicate: the same page also referenced from a comment
        {"id": "12345", "type": "confluence", "title": "5a. Catalog service contract", "origin": "jira-comment", "depth": 1, "path": ["DEMO-1234", "comment#3", "12345"], "version": 44},
    ],
}


def _by_id(rows):
    return {f["id"]: f for f in rows}


def test_levels():
    f = _by_id(prioritize.prioritize(ENTRADA, budget=12))
    assert f["12345"]["level"] == "P1"
    assert f["DEMO-1233"]["level"] == "P1"          # strong link "is tested by"
    assert f["DEMO-2000"]["level"] == "P2"          # epic
    assert f["12346"]["level"] == "P2"         # body of a P1
    assert f["12347"]["level"] == "P3"         # ancestor (index)
    assert f["12348"]["level"] == "P3"         # depth 3
    assert f["12349"]["level"] == "P3"         # unreferenced search


def test_search_never_outranks_referenced():
    rows = prioritize.prioritize(ENTRADA, budget=12)
    worst_referenced = min(f["score"] for f in rows if not f["origin"].startswith("search") and f["level"] != "P3")
    assert all(f["score"] < worst_referenced for f in rows if f["origin"].startswith("search"))


def test_wip_penalized_and_duplicate_merged():
    f = _by_id(prioritize.prioritize(ENTRADA, budget=12))
    assert "title is WIP/legacy/deprecated" in f["12348"]["reasons"]
    assert len(f["12345"]["paths"]) == 2
    assert sum(1 for x in prioritize.prioritize(ENTRADA, 12) if x["id"] == "12345") == 1


def test_actions_and_budget():
    f = _by_id(prioritize.prioritize(ENTRADA, budget=2))
    assert f["12345"]["action"] == "read" and f["DEMO-1233"]["action"] == "read"   # P1 always
    assert {f["DEMO-2000"]["action"], f["12346"]["action"]} == {"suggest"}         # no budget left for P2
    assert f["12349"]["action"] == "suggest"


def test_disallowed_space_is_never_read():
    entrada = {
        "root": {"type": "jira", "id": "DEMO-1"},
        "references": [
            {"id": "1", "type": "confluence", "title": "Contract", "origin": "jira-description", "depth": 1, "url": "https://confluence.example.org/spaces/XP/pages/1/Contrato"},
            {"id": "2", "type": "confluence", "title": "Another area", "origin": "jira-description", "depth": 1, "url": "https://confluence.example.org/spaces/OTHER/pages/2/Otra"},
            {"id": "3", "type": "confluence", "title": "No known space", "origin": "jira-description", "depth": 1},
        ],
    }
    f = _by_id(prioritize.prioritize(entrada, budget=12, spaces={"XP"}))
    assert f["1"]["action"] == "read"
    assert f["2"]["action"] == "out-of-space"
    assert f["3"]["action"] == "read"
    # With no filter configured, everything is allowed
    assert _by_id(prioritize.prioritize(entrada, budget=12, spaces=set()))["2"]["action"] == "read"


def test_src_ids_are_consecutive():
    rows = prioritize.prioritize(ENTRADA, budget=12)
    assert [f["src"] for f in rows] == [f"SRC-{i:02d}" for i in range(1, len(rows) + 1)]
    assert rows[0]["level"] == "P1"
