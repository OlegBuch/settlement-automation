---
name: design-tests
description: Full source-grounded test-design flow for a Jira ticket in settlement-automation — collects Jira/Confluence sources, builds the risk register and P0–P3 coverage matrix, records data/environment needs and open questions, hands the ready rows to scenario-creation to write Cucumber scenarios, self-reviews, and updates the qa-design memory. Leaves qa-design/features/<KEY>-<slug>/. Use it when the user says "design <KEY>", "/design-tests <KEY>", or asks to plan and write the tests for a ticket.
source: qa-harness · harness/skills/design-tests (adapted: output is Gherkin, not Xray cases)
---

# Design the tests of a ticket

Read first: `qa-design/policies/*.md`. Deliverables in English.

```
qa-design/features/<KEY>-<slug>/
  00_README.md                      # purpose, reading order, scope, exclusions
  sources/                          # collect-sources output (manifest, snapshots, images/, code/)
  01_sources-and-architecture.md    # sources summary, diagrams, business rules with citations
  02_data-and-environment.md        # target envs, data each row needs, env guards, cleanup, access
  03_coverage-matrix.md             # coverage-plan: risk register + P0–P3 rows
  04_scenarios.md                   # row ID -> feature file:line / Scenario name, or why not automated
  10_risks-questions-decisions.md   # Q-xx open questions, D-xx decisions, conflicts between sources
  reviews/                          # qa-reviewer output
```

## Steps

0. **Memory.** Grep `qa-design/knowledge/` for the key, epic, components and endpoints; tell the user which earlier
   designs relate. If cards exist, `uv run qa-design/tools/confluence/versions.py memory` shows pages that changed.
1. **Sources.** Skill `collect-sources <KEY>`. Confirm the suggested reads with the user. Write
   `01_sources-and-architecture.md`.
2. **Data and environment.** `02_data-and-environment.md`: which env (`dev`, `devtest`, `preprd`) has the products,
   programs, registrations and users each area needs (check `configuration.json` keys and
   `Documentation/*.md`, never secrets); env guards; cleanup; unknowns as `[[MISSING_INFO]]`.
3. **Coverage.** Skill `coverage-plan` → `03_coverage-matrix.md`.
4. **Self-review of the plan.** Launch the `qa-reviewer` agent with `review_type: coverage`, the matrix and
   `sources/`. Fix confirmed findings; **at most 2 rounds**; report what stays open.
5. **Questions gate.** Show the user the `blocked` rows and their `Q-xx`. Proceed with `ready` rows only; blocked rows
   wait for answers (the user may answer now — update the matrix and cite "user, <date>" as the source).
6. **Scenarios.** Skill `scenario-creation`, passing the pack path. It writes Gherkin for `ready` rows (one scenario
   or outline per row or group of rows), with the row ID in a comment above each `Scenario:`, and runs the compile +
   dry-run verify. Write `04_scenarios.md` mapping each row to `file:line`, or to why it was not automated.
7. **Review.** `qa-reviewer` with `review_type: feature` on the changed `.feature` files against the matrix. Fix
   confirmed findings (max 2 rounds).
8. **Close.** `10_risks-questions-decisions.md`, `00_README.md`, then skill `close-session` for the memory.
   Delivery (commit / PR) follows the mode chosen in `scenario-creation`.

## When done

Summarize: rows by priority and status, scenarios written (files), verify result, live run (env + result, or "not
run"), the most important open questions, and what is needed before the blocked rows can be automated.
