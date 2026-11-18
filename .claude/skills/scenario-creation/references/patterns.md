# Scenario and file patterns

How a good API scenario is shaped. `rules.md` says what is forbidden; this says what to aim for.

## Files

- Group by API / component folder, one business feature per file (adapter → Layout).
- The `Feature:` name is unique across the suite — grep before naming.
- Put the ticket and design links in the feature description, under the `Feature:` line.
- Extending an existing feature is the default. A new file is for a genuinely new feature
  (new endpoint, new pipeline stage, new program).

## Background

Only what every scenario in the file needs: fresh context, env guard (if any), login, and program /
time-zone settings. Nothing that creates data.

```gherkin
Background:
  Given I start with an empty context
  And I log in as a settlement API admin
```

## Scenario title

Descriptive and unique within the file. When the request carries a test-case or ticket reference,
put it first: `Scenario: ITAPPSIT-4292 - PATCH timebound row with null optional fields`.

## Scenario shape — arrange, act, assert, clean up

Shape only — the status and message below are illustrative; take real ones from the spec.

```gherkin
Scenario: <one business intention>
  # arrange: create or locate the data this scenario owns
  When I POST a settlement with the following properties:
    | settlement_type | ONGOING_DATA_SUBMISSION |
    | event_id        | <uuid>                  |
  Then the response should include the new settlement

  # act + assert: one call, then its checks
  And I expect the next API call to return a status code of 400 and message of "Bad Request"
  When I POST a settlement_item with the following properties:
    | settlement_id | <last-settlement-id> |
  Then the expected status should be returned

  # cleanup
  When I DELETE the settlement
  Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
```

- One business intention per scenario. A journey (create → update → read → delete) is fine when the
  journey is the intention.
- Blank line between beats; `# cleanup` marks the teardown block.
- Set the expected status **before** the call when the suite works that way
  (`I expect the next API call to return …`), then assert it after.
- No implementation detail in the wording (no raw URLs, headers or JSON paths in Gherkin) — steps hide
  that.

## Negative and validation cases

- One invalid input per scenario, or a `Scenario Outline` over invalid inputs with the expected
  status and message in `Examples`.
- Assert both the status code and the error message / details the spec defines.
- Authorization: one row per role (`<role>` in the login step) with the expected status.

## Data variations

`Scenario Outline` + `Examples` rather than copy-pasted scenarios with one value changed.

```gherkin
Scenario Outline: <role> cannot DELETE a settlement
  And I log in as a settlement API <role>
  ...
  Examples:
    | role | code |
    | user | 403  |
```

## Picking a step

1. Grep the step globs for the verb and the resource (`POST a settlement_item`, `DELETE`,
   `GET settlement_item_timebound`).
2. Copy the phrase **exactly**, including the data-table shape the method reads
   (`asMap` = two columns key | value; `asMaps` = header row + rows).
3. Check which placeholders the method resolves (`<uuid>`, `<last-…-id>`, saved tags).
4. Only when nothing fits: add a step in the class that owns that resource, in the suite's voice.

## Pipeline scenarios

- Generate the expectation first (suite steps that compute expected settlements / items), then run
  the pipeline, then poll until done, then compare.
- Poll with the suite's `I wait until …` steps.
- Guard to the environment where the program / product hierarchy exists.
