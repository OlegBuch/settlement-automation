# API test-design patterns

Adapted from qa-harness `qa-test-design-patterns` (origin `qa-agents`, commit `abf5c6d`): API categories, risk and
priority guides kept; UI categories and Xray-specific advice removed; settlement-specific categories added.
Use it to decide **which scenarios** a ticket needs. Expected values still come only from the sources.

## API categories (consider each; mark not-applicable ones with a reason)

1. **Happy path** — valid input → documented status (`200` / `201` / `204`) and body fields / schema.
2. **Authentication** — no session / API key, invalid or expired credentials → documented status (usually `401`).
3. **Authorization** — each role the ticket names (`admin`, `user`, `prdadmin`, `no_product_access`,
   `no_stm_roles_user`, ECO roles) → documented status (usually `403`); access to another org's / product's data.
4. **Invalid input** — one invalid field at a time: missing required, wrong type, invalid enum, malformed UUID,
   empty body, body not an array / object as specified → `400` + the documented message / details.
5. **Edge cases** — not found (`404`), boundaries (min / max / ±1), empty strings, unicode, max page size,
   duplicate / idempotent PUT and DELETE, concurrent updates when the contract defines it.
6. **State changes** — after POST / PUT / PATCH / DELETE, verify with a follow-up GET (and `include_deleted` when soft
   delete); GET must not change state; audit-log rows when the API keeps them.
7. **Schema** — field names, types, nullable fields present as `null`, enum sets, ISO-8601 `*_dttm_utc` values,
   paging metadata.
8. **Error handling** — consistent error body, no stack traces or internals leaked, downstream failure behaviour
   when documented.
9. **Logging & PII** — no credentials in URLs or logs; sensitive operations audited.
10. **Performance sanity** — only when the ticket states an SLA or payload limit (see `Performance/` features).

## Settlement-specific categories

11. **Time** — time zone of the program (e.g. `America/Edmonton` for AESO), DST transitions, interval rounding,
    month / quarter boundaries, `start == end` instants, open-ended `end_dttm_utc`.
12. **Pipeline / async** — submission and completion are separate steps; completion via a polling step with a
    timeout; skipped / failed states; dead-letter queues; re-runs (`FINAL` vs preliminary modes).
13. **Calculations** — expected values from the documented formula (aggregation registration → portfolio, payment,
    penalties), numeric comparison scale-insensitive.
14. **Data lifecycle** — what the scenario creates, how it is cleaned up, which env holds the reference data it needs.

## Environment risk (`env_risk`)

| Level  | Definition                                                     | Action                                           |
| ------ | -------------------------------------------------------------- | ------------------------------------------------ |
| Safe   | Read-only                                                      | Any env                                          |
| Low    | Creates data the scenario deletes again                        | dev / devtest / preprd; cleanup asserted         |
| Medium | Modifies existing shared data, reversibly                      | Env guard; restore in the same scenario          |
| High   | Bulk delete / re-create settlements, triggers external systems | Env guard to preprd (or as agreed); user's OK    |

Questions: does it create, modify or delete data? Trigger lambdas / queues / external systems? Is it reversible
without manual work? Could a failure leave inconsistent data for other testers?

## Priority (P0–P3)

| Criteria        | P0                   | P1                 | P2               | P3          |
| --------------- | -------------------- | ------------------ | ---------------- | ----------- |
| Business impact | Wrong money / settlement | Workflow blocked | Inconvenience  | Cosmetic    |
| Frequency       | Every run            | Common             | Uncommon         | Rare        |
| Data risk       | Loss / corruption    | Incorrect data     | Display / message | None       |
| Workaround      | None                 | Difficult          | Easy             | Not needed  |

## Scenario generation

- All valid → happy path. One invalid at a time → validation rows. Boundaries → min, max, min-1, max+1.
- Dependent fields (B required only when A = X) → one row per dependency.
- Variations that differ only in data → one row with an "outline" note (becomes a `Scenario Outline`).

## Anti-patterns

| Anti-pattern            | Correct approach                                                      |
| ----------------------- | --------------------------------------------------------------------- |
| "It should work"        | Status + specific body fields / DB state, with the source cited       |
| Only happy path         | Walk all categories; justify each not-applicable one                  |
| Interdependent rows     | Each row creates or locates its own data                              |
| Fixed waits             | Polling with a timeout                                                |
| No `env_risk`           | Classify every row                                                    |
