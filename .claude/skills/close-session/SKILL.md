---
name: close-session
description: Closes a test-design or review session by proposing updates to the qa-design long-term memory (feature card, component cards, index, trusted sources) and applying them after approval. Use it when finishing design-tests or a relevant review, or when the user says "save this to memory" / "let's close the session".
source: qa-harness · harness/skills/close-session (adapted)
---

# Close the session: update the memory

## What is saved (and what is not)

- **Yes**: what was designed or reviewed, confirmed business rules (with source), Confluence pages used **with their
  version and space**, components / endpoints / lambdas / queues / tables involved, decisions, open questions and
  status, coverage gaps, `.feature` files and coverage IDs, behaviour learned about a component (timing, DST,
  idempotency), sources rated useful or not.
- **No**: copies of pages, full payloads, secrets, personal data, environment UUIDs beyond what `configuration.json`
  already holds, opinions without a source, conversation detail.

## Steps

1. Identify the key and its pack `qa-design/features/<KEY>-*`.
2. **Feature card** `qa-design/knowledge/features/<KEY>.md` (from `_templates/card-feature.md` if absent): prepare the
   diff. Update `confluence:`, `coverage_ids`, `feature_files`, `status`, `updated`.
3. **Components**: add what was learned to each touched component card and the key under `features:`. Create a card
   when a component appears in 2+ features.
4. **Relations**: `[[...]]` links between cards that share an endpoint, queue or data.
5. **Trusted sources**: `qa-design/knowledge/trusted-sources.yaml`.
6. **Index**: add / update the line in `qa-design/knowledge/index.md`.
7. **Show and approve**: present the full diff; apply only what is approved.
8. **Delivery**: the memory goes to the repo through the normal `commit` / `github-pr` flow (same branch as the
   scenarios, or its own `ITAPPSIT-0000-Update-qa-memory` branch). Do not commit unless the user asks.

## Quality

- Every verifiable fact carries its source.
- A contradiction with the card is never overwritten silently: record it ("before X per page v40, now Y per v44").
