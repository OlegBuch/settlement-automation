# Language and format

Adapted from qa-harness `guides/policies/language-and-format.md`. Unlike the original harness, the output here is
automated Cucumber, not manual Xray cases.

- Talk to the user in the language they write in. Write deliverables (design packs, coverage matrices, memory cards,
  Gherkin) in **English**. Keep source quotations and contract literals in their original language.
- Design-pack rows follow Arrange-Act-Assert: setup and data, the API call, then observable expected results
  (status + body / DB / downstream state).
- Coverage rows have stable IDs `<KEYNODASH>-<GROUP>-<NNN>` (e.g. `ITAPPSIT4292-TB-001`) that are never renumbered.
  The scenario that implements a row carries the ID in its comment line above `Scenario:`, so coverage stays
  traceable from Gherkin back to the pack.
- Gherkin itself follows `.claude/skills/scenario-creation/`.
