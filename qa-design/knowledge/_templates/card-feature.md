---
key: ITAPPSIT-0000
title: "<Jira summary>"
epic: ITAPPSIT-0000
status: designed            # designed | in-review | executed | closed
components: []             # names matching knowledge/components/<name>.md
endpoints: []               # API paths
streams_queues: []           # streams, queues
tables: []                  # collections/tables
confluence:                 # pages used, with the version read (versions.py detects changes)
  - {id: "000000000", title: "<page title>", version: 1, space: XP}
coverage_ids: []            # row IDs from 03_coverage-matrix.md
feature_files: []           # src/main/resources/... .feature files that implement them
package: qa-design/features/ITAPPSIT-0000-<slug>
updated: YYYY-MM-DD
---

# ITAPPSIT-0000 — <title>

## Summary
<!-- 3-5 lines: what the feature does and what was tested. -->

## Business rules covered
<!-- One bullet per rule, each with its source: (page <id> v<version> §Section) or (ITAPPSIT-0000 AC-2). -->

## Test data and environments
<!-- Which data were used and why; environment constraints. No secrets, no personal data. -->

## Decisions and assumptions
<!-- D-xx: decision — reason — who/when. -->

## Open questions
<!-- Q-xx: question — status — impact on cases. -->

## Coverage gaps and risks
<!-- What is knowingly not covered, and the risk. -->

## Related
<!-- [[ITAPPSIT-0000]], [[components/settlement-api]] — how they relate. -->
