---
name: coverage-plan
description: Builds the risk register and the P0–P3 coverage matrix for a Jira ticket from its collected sources, using the API / settlement test-design patterns. Writes qa-design/features/<KEY>-*/03_coverage-matrix.md. Use it from design-tests, or when the user asks for a test plan, risk analysis or coverage matrix for a ticket.
source: qa-harness · lean replacement for bmad-tea-test-design (BMAD/TEA not vendored here)
---

# Coverage plan: risks + P0–P3 matrix

Read first: `qa-design/policies/*.md` and `references/api-test-patterns.md`.

## Input

- `qa-design/features/<KEY>-*/sources/` and `01_sources-and-architecture.md` (run `collect-sources` first if the
  manifest is missing).
- `02_data-and-environment.md` if it exists.
- Related cards in `qa-design/knowledge/` and existing coverage in `src/main/resources/**/*.feature`
  (grep the endpoint / resource names): existing scenarios are not re-planned, they are listed as `covered`.

## Steps

1. **Testable items.** List every acceptance criterion and every business rule from the sources, each with its
   citation (`ITAPPSIT-1234 AC-2`, `page 805514841 v12 §Error handling`).
2. **Risks.** Risk register `R-xx`: what could go wrong for the business, probability (1–3) × impact (1–3), score,
   and the sources. Score ≥ 6 → must have P0/P1 coverage.
3. **Coverage rows.** For each testable item, walk the categories of `references/api-test-patterns.md`. One row per
   scenario; not-applicable categories get one line with the reason.
4. **Classify** each row: priority P0–P3, `env_risk`, environments where its data exists, status:
   `ready` (all expected values sourced) · `blocked Q-xx` (contains `[[MISSING_INFO]]`) · `covered` (existing
   scenario, give `file:line`) · `out-of-scope` (reason).
5. **Write** `03_coverage-matrix.md`.
6. Add new questions / conflicts to `10_risks-questions-decisions.md`.

## Output format

```markdown
Document Note: Missing information is marked as [[MISSING_INFO]].

# ITAPPSIT-4292 — Coverage matrix

## Risk register
| ID | Risk | P | I | Score | Source |
|---|---|---|---|---|---|
| R-01 | Overlapping timebound rows accepted → double payment | 2 | 3 | 6 | ITAPPSIT-4292 AC-3 |

## Coverage
| ID | Category | Scenario (AAA, one line) | Expected (status + body / state) | Source | Risks | Priority | env_risk | Env | Status |
|---|---|---|---|---|---|---|---|---|---|
| ITAPPSIT4292-TB-001 | Happy path | POST full optional field set, GET list | 200 OK; row returned with all fields | ITAPPSIT-4292 AC-1 | R-01 | P0 | Low | dev, preprd | ready |
| ITAPPSIT4292-TB-007 | Invalid input | PATCH with end < start | [[MISSING_INFO]] | — | R-01 | P1 | Low | dev | blocked Q-02 |

## Not applicable
- Performance sanity: no SLA in the sources.

## Summary
P0: n · P1: n · P2: n · P3: n — ready: n · blocked: n · covered: n · out-of-scope: n
```

Row IDs: `<KEY without dash>-<GROUP>-<NNN>`; the group is the resource / flow (e.g. `TB`, `STM`, `AUTH`).
IDs are never renumbered once a scenario implements them.

## Rules

- No row without a source for its expected result; unknown → `[[MISSING_INFO]]` + `Q-xx`, status `blocked`.
- Do not skip a testable item; if it cannot be automated (needs a manual or visual check), mark `out-of-scope` and
  say why.
