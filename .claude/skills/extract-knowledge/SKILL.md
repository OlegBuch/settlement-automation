---
name: extract-knowledge
description: Bootstraps or extends the qa-design memory from material that already exists — existing .feature files and Documentation/ in this repo, earlier design packs, or folders the user supplies — proposing feature and component cards and index lines. Use it only when the user asks to build or extend the memory from existing material.
source: qa-harness · harness/skills/extract-knowledge (adapted)
---

# Extract knowledge into qa-design/knowledge/

## Input

One or more of: `src/main/resources/<area>/` (existing features), `Documentation/*.md`, `qa-design/features/*`, or a
folder the user names. If nothing is named, ask.

## Steps (one area / folder at a time)

1. **Inventory**: list `.feature`, `.md` and manifest files. Skip binaries, `target/`, credential files
   (`.env`, `ATLAS_SESSION_*`, `config/creds-alias.conf`, `config/*.local.json`).
2. **Extract, citing the origin file (and line)**:
   - Jira keys and Confluence / Jira links found in `Feature:` descriptions and comments.
   - Components: APIs and endpoints (from step definitions and `Context` URL constants), lambdas, SQS queues,
     Postgres tables / schemas, programs (AESO, FCAS), environments a feature is guarded to.
   - Confluence pages with ID and version when known (`version: null` otherwise).
   - Business rules visible in assertions, decisions, open questions, known gaps (`Deferred/`, `This scenario fails
     because …`).
   - Domain terms defined in the sources.
3. **Propose** (show before writing): feature cards (`_templates/card-feature.md`), component cards
   (`_templates/card-component.md`, extend rather than duplicate), index lines, trusted sources only when a document
   shows the page was the main source.
4. **Approve and write** only what the user approves. No secrets, no personal data, no environment UUIDs.
5. **Closing**: suggest committing through the normal `commit` / `github-pr` flow.

## Quality

- A card summarizes and points; under ~120 lines.
- Every verifiable fact carries its source.
- Contradictions between sources are recorded as questions in both cards, not resolved by guess.
