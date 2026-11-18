# Hard constraints

MUST / MUST NOT. Suite-agnostic: every concrete path, command, step phrase and environment comes from
the adapter. If a rule here and the adapter disagree on a fact, the adapter wins — and the rule is
wrong and should be fixed.

## Requirement and expected values

- MUST take endpoints, request fields, status codes, error messages and business rules from the
  request (Jira ticket, acceptance criteria, API technical design, Swagger) or from a response you
  actually observed. Never from memory or "what the API probably returns".
- When the source is ambiguous about an expected value, ask. Do not encode a guess as an assertion.
- Expected calculated values (pipeline results, payments, aggregations) MUST come from the stated
  formula / spec or from the suite's own expectation-generating steps, not hard-coded from one
  observed run unless the request says the data is fixed (e.g. a known preprd dataset) — and then the
  scenario says so in a comment.
- A ticket can be stale. If the scenario cannot meet the acceptance criteria as written, report why
  and what should change. Do not ship a weaker scenario silently.

## Steps

- MUST use an existing phrase copied exactly. A new step is allowed only when no existing phrase,
  and no combination of existing phrases, can do the job. Grep the adapter's step globs before
  concluding that.
- When a new step is the only option, add its implementation in the **same change** and use it.
  Unmatched Gherkin is never left behind (the dry-run reports it as `undefined`).
- MUST NOT add a phrase that also matches an existing definition (`ambiguous` at dry-run) or a
  near-duplicate of one.
- New wording MUST follow the suite's voice (adapter → Step conventions): first person
  `I …`, Cucumber expressions (`{string}`, `{int}`, `{word}`, custom parameter types) preferred over
  new regexes, data tables for request bodies.
- A new step MUST assert something when it is a `Then` (JUnit `assert…` / `fail`), and MUST NOT
  swallow exceptions.
- Step implementations MUST stay environment-agnostic: URLs, users, IDs come from the config
  accessor / `Context`, never hard-coded in Java.

## Data, IDs and secrets

- MUST NOT hard-code an environment-specific ID in Java. In a `.feature`, an ID is acceptable only
  when the scenario is guarded to the environment where that ID exists (adapter → env guard), or when
  the adapter lists it as shared across environments.
- Prefer generated data (`<uuid>` etc.) and saved values from earlier steps over fixed IDs.
- MUST NOT write passwords, API keys, tokens, session values or Okta settings into features, steps,
  config or logs.
- MUST NOT change shared reference data (product rules, registrations, financial-point mappings,
  ITS mappings) unless that is the subject of the test, and then restore it in the same scenario.

## Shared environments

- MUST clean up what the scenario creates (delete settlements / items / rows it posted) at the end of
  the scenario, using the suite's delete steps, and assert the delete succeeded.
- MUST NOT delete or modify data the scenario did not create, except in the explicitly guarded
  "re-create" pipeline scenarios the adapter describes.
- MUST NOT depend on another scenario having run first. Each scenario creates or locates its own data.

## Waiting

- MUST prefer the suite's polling steps (`I wait until …`) for asynchronous work (pipeline, lambdas,
  queues). A fixed wait (`I wait N seconds`) is only for a gap no polling step covers, is as short as
  works, and is never the pass condition.

## Scenario files

- One business feature per `.feature` file. Several scenarios per file are expected.
- Every scenario MUST end with an assertion (a `Then`), and each `When` that calls an API is followed
  by a status / content check before the next action.
- `Scenario Outline` + `Examples` instead of copy-pasted scenarios that differ only in data. Every
  `<param>` used, every column used.
- Tags only from the adapter's list. Do not invent tags.
- MUST NOT leave debug steps (`log on`, `stop`, `I want to turn on all logging`) in a delivered
  scenario unless the request asks for them.
- MUST NOT ship a new scenario disabled, commented out, or failing on purpose.

## Scope of the change

- Stay inside the suite the adapter names. Do not edit the APIs, lambdas or infrastructure under test.
- Do not refactor unrelated step classes in the same change.

## Error handling

| Failure                                          | Action                                                                                                                        |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| Dry-run: `undefined` step                        | Rewrite to an existing phrase. Add a step only when none can do the job, in the same change.                                  |
| Dry-run: `ambiguous` step                        | The phrase matches two definitions. Change the new phrase, never the existing one.                                            |
| Compile error in a new step / model change       | Fix the implementation. A green dry-run is not a pass when Java does not compile.                                             |
| Live run: 401 / 403 on login                     | Credentials / session / VPN issue on the user's side. Stop and report; do not change login code.                              |
| Live run: data not found                         | Check the env guard and the config IDs for that env. Do not swap in an ID from another env.                                   |
| Live run: API returns something the spec forbids | Report it as a probable API bug with request, response and spec reference. Do not loosen the assertion.                       |
| Live run: flaky timing                           | Replace the fixed wait with a polling step; do not raise the sleep.                                                           |
| Feature with the same name exists                | Extend that file instead of creating a new one.                                                                               |
| Static verify red three times                    | Stop, report the last output, follow `Delivery` with the failure stated (autonomous) or hand back (guided). No fourth pass.   |
| Push or `gh pr create` fails                     | Stop and report that error. Do not open a second pull request.                                                                |

Verify commands are deliberately **not** listed here — they live in the adapter.
