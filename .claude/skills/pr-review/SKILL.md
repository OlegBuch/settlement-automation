---
name: pr-review
description: >
  Review the current settlement-automation branch locally (Java step definitions, model classes,
  Cucumber features, config, SQL) and draft review comments in chat, including before a pull
  request exists. Trigger on `/pr-review`, or "review my branch / changes before I push".
  Read-only: never posts, never edits.
version: 1.1.0
source: app-bedrock-tvjs · .agents/skills/pr-review (adapted — no review bot in this repo)
---

# Local PR review

A local pre-push review for this repo. There is no CI review bot here, so this skill carries its own
checklist. For `.feature`-heavy changes, `scenario-review` is the deeper check; this skill covers
the whole diff.

## Scope

- Read-only. Do not edit files, push, approve, or post comments.
- Do not run scenarios against a live environment. Static checks only: `mvn -q compile` and the
  Cucumber dry-run from `scenario-creation/adapters/settlement-automation.md`.

## Inputs

An open pull request is optional; reviewing before the first push is the normal case.

1. **Diff** — the patch this branch would put in its PR, **including uncommitted changes**. Do not
   use `git diff <base>...HEAD` (that drops the working tree). Base, in order:
   1. this branch has an open PR (`GH_HOST=<GITHUB_HOST> gh pr view`) → `upstream/<baseRefName>`;
   2. otherwise `upstream/develop` (fetch it first); `origin/develop` only when there is no `upstream`.

   The diff is `git diff <base>`. Exclude the local-only noise and say you did: the
   `env` / `awsKeyset` switch in `configuration.json`, `ATLAS_SESSION_*`, `target/`, `.idea/`.
   If the remaining diff is empty, say so and stop.
2. **Existing threads** — only when this branch has an open PR: skip anything already raised.
3. **Context** — for every changed step phrase, the `.feature` files that use it
   (`grep -rn "<phrase start>" src/main/resources`); for every changed `Context` / `Utility` /
   model member, its callers.

The chat stands in for the PR description: stated intent counts. Do not invent intent.

## Checklist

### Correctness (🔴 when it breaks a run or gives a false pass)

- A step whose assertion can never fail (missing `assert…`/`fail`, assertion on the request
  instead of the response, `assertTrue(list.size() >= 0)`, swallowed exception).
- Changed step regex / Cucumber expression that no longer matches existing `.feature` usages, or
  now matches two definitions (ambiguous). Confirm with the dry-run.
- `Context` state that leaks between scenarios (static fields not reset by
  `I start with an empty context`), or step classes relying on another class's instance field
  instead of `Context`.
- Data created without cleanup in the scenario, or cleanup that deletes data it did not create
  (shared environments — other people's settlements live there).
- Time zone / DST mistakes: local time vs `*_dttm_utc`, interval rounding, month boundaries,
  `ZonedDateTime` vs `LocalDateTime`.
- Number comparison with `equals` on `Double`/`BigDecimal` where scale differs; use the existing
  helpers (`Utility.areDoublesEqualEnough`, `BigDecimal.compareTo`).
- Hard-coded environment-specific IDs (product, program, org UUIDs) in a step body; they belong in
  `configuration.json` or the `.feature`, and a scenario that needs one env says so with
  `Given this scenario is only supported for the <env> environment`.

### Security (🔴/🟠)

- Passwords, API keys, tokens, `ATLAS_SESSION` values, Okta settings in any committed file or log
  line. Logging full request headers / auth responses.
- A password added back to `configuration.json`, or any credential not going through
  `EcoCredentials` / AWS Secrets Manager.

### Maintainability (🟡)

- A new step that duplicates an existing phrase or helper (grep `stepdefs/`, `Utility`, `RequestContainer`).
- Dead code, commented-out blocks, debug `stop` / `log on` steps left in features.
- Copy-pasted scenarios that should be a `Scenario Outline`.
- Unused imports, raw types, `System.out` instead of the class `LOG`.

### Feature hygiene (🟡)

- Scenario names unique within the file and descriptive; Jira link in the `Feature:` description
  when there is a ticket.
- Background contains `I start with an empty context` and the login step.

## Verify before reporting

Open the file at the cited line and the callers / features the claim depends on. Drop what the
code does not support. Re-rate severity from the impact you checked, not from first impression.
Report a finding only when the code supports it — no guesses.

## Report

In chat, one comment per surviving finding, most severe first, ready to paste:

```
**🤖 [Code Review] <🔴|🟡> : <one short sentence>**   (or 🔒 [Security Review] <🔴|🟠|🟡|🟢>)
`path:line`
<what is wrong and the concrete impact>
**🩹 Fix:** <only when the fix is safe and small>
```

Then: the base used, whether uncommitted changes were included, the static checks run and their
result, the dropped candidates with one-line reasons, and a reminder that nothing was posted.
