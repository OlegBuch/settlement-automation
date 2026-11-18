# Suite mechanics

Runner and API-testing constraints that decide whether a scenario is runnable and safe. Suite-
agnostic: the adapter supplies the paths and commands.

## Binding is checked by a dry-run

- Cucumber binds each Gherkin step to exactly one step definition in the glue package. A dry-run
  (`--dry-run`) parses every feature and reports `undefined` and `ambiguous` steps without executing
  anything or calling any API. It is the cheapest feedback available — run it after every change to
  Gherkin or a step pattern.
- A dry-run does **not** validate step arguments: IDs, field names, enum values, and expected messages
  are only checked by a live run.

## State between steps

- Cucumber creates a new instance of every step class per scenario. Instance fields are scenario-
  scoped; values that one step class must hand to another go through the suite's shared context
  object (adapter → State), not through `static` fields.
- A scenario starts by resetting that context (adapter → Background). Never rely on what a previous
  scenario left in it.
- Saved values ("save … id with the tag X", `<last-…-id>`) live in the context and are scoped to the
  scenario.

## Shared, live environments

- Scenarios run against real deployed APIs, lambdas, queues and databases shared with other testers
  and developers. Every row a scenario creates is visible to them.
- Create what you need with generated identifiers, clean it up at the end, and assert the cleanup.
- Never sweep-delete by pattern. Delete by the IDs this scenario saved.
- A scenario that needs data only one environment has must guard itself to that environment.

## Asynchronous work

- Pipeline stages, lambdas and queues complete asynchronously. Use polling steps that wait until a
  condition holds with a timeout. A fixed sleep is a last resort, never the pass condition.

## Assertions

- Assert on the response (status, body fields, error message), or on the database / downstream state
  the API is supposed to change — something the API contract guarantees.
- Compare numbers numerically (scale-insensitive) and timestamps after normalisation to UTC.
- Do not assert on fields the API does not guarantee (ordering without a sort parameter, server-
  generated timestamps to the millisecond, audit IDs).

## Auth

- Log in with the suite's login steps, which fetch credentials from the secret store / config. Never
  add a parallel auth path or inline a token.
- Authorization scenarios switch role via the login step, not by editing headers in Gherkin.

## Logging

- Request / response logging steps exist for debugging. Keep them out of delivered scenarios; never
  log credentials or session values.
