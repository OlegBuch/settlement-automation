# Missing information policy (mandatory)

Adapted from qa-harness `guides/policies/missing-info.md`.

- Every design-pack document starts with: `Document Note: Missing information is marked as [[MISSING_INFO]].`
- Use **only** `[[MISSING_INFO]]` for unknown values. Never `<TBD>`, `TBD`, `TODO`, `???` or similar.
- Do not invent a missing value; keep `[[MISSING_INFO]]` and add the question (`Q-xx`) to
  `10_risks-questions-decisions.md`.
- A coverage row with any `[[MISSING_INFO]]` in its expected result is `blocked` by its `Q-xx`: no Gherkin scenario
  is written for it until the question is answered. `[[MISSING_INFO]]` never appears in a `.feature` file.
- Edge cases or error states not defined in the sources are marked explicitly as out of scope, not guessed.
