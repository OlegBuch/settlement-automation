---
name: scenario-review
description: >
  Review a settlement-automation pull request (or local branch) that adds or changes Cucumber
  scenarios. Trigger on `/scenario-review <PR>`, or when asked to review a scenario / `.feature`
  change. Checks the scenarios against the Jira ticket / acceptance criteria, the scenario-creation
  rules, and the rest of the feature file. Read-only: drafts comments, never posts them.
version: 1.0.0
source: app-bedrock-tvjs · .agents/skills/scenario-review (adapted — Jira instead of Squash)
---

# Scenario review

The reviewer's companion to `scenario-creation`. That skill defines what a correct scenario is;
this one checks a change against it. Do not restate its rules here — read them.

Generic code review looks at the diff. The defects that matter in a scenario change are usually
outside it: an acceptance criterion with no scenario, a step whose Java never asserts, data left
behind on a shared environment, a description with no proof the scenario ran. Look there first.

## Scope

- Read-only. Do not edit files, push, approve, or post comments. Draft the comments; the human
  reviewer decides and posts them.
- Do not run scenarios against a live environment. Static checks from the adapter (compile,
  Cucumber dry-run) are allowed on a checkout of the branch; say when you did not run them.

## Inputs — gather before judging

1. **The change**: with a PR number, `GH_HOST=<GITHUB_HOST> gh pr view <n> -R
   xplatform/settlement-automation` (title, description, files, commits) + `gh pr diff` + review
   threads. Without one, the local branch diff against `upstream/develop`, including uncommitted
   changes.
2. **Whole feature files** on the head, not only the hunks: `Feature:` description and links,
   Background, neighbouring scenarios, overlapping scenarios elsewhere in the folder.
3. **The step definitions** behind every phrase the new scenarios use — new or existing — so you
   know what each step really sends and asserts.
4. **The requirement**: the design pack `qa-design/features/<KEY>-*/` when it exists (coverage matrix
   + sources; map rows to scenarios by the row-ID comments), otherwise the Jira ticket (ITAPPSIT- / BDAP-)
   linked in the feature or PR, its acceptance criteria, and the API technical design if referenced.
   The `qa-reviewer` agent (`review_type: feature`) can run the source-citation pass with a clean context. If you cannot open it, ask the
   user to paste the criteria. Never review against a guess.
5. **The rules**: `../scenario-creation/references/rules.md`, `patterns.md`, `suite-mechanics.md`,
   and `../scenario-creation/adapters/settlement-automation.md`.
6. **Other open PRs touching the same files** (`gh pr list -R xplatform/settlement-automation
   --search <path>`): conflicts and duplicated scenarios.

## Checklist

Record each finding with `file:line` on the head.

### 1. Requirement coverage

- Map every acceptance criterion to the scenario lines that check it. Output this as a table.
- Each criterion has an observable assertion (status + body / DB state), not only an action.
- Positive and negative paths the ticket names are both covered; authorization by role when the
  ticket mentions permissions.
- Expected values (status codes, messages, numbers) match the ticket / design, not just whatever the
  API returned.
- Deviations (stale ticket, criterion that cannot be automated) are allowed only when the PR says
  so. An unexplained gap is a blocker.

### 2. Scenario-creation rules

- Steps: existing phrases reused; a new step only when nothing existing does the job; new `Then`
  steps actually assert; no `ambiguous` phrase (dry-run).
- Background: `I start with an empty context`, then login; env guard when data is env-specific.
- Data: created with generated IDs, cleaned up at the end with the delete asserted; nothing deleted
  that the scenario did not create (except the documented preprd re-create scenarios).
- No env-specific UUIDs without a guard; no IDs, URLs or users hard-coded in Java.
- No secrets anywhere; no `configuration.json` env / credential change in the diff.
- Waiting via polling steps; fixed waits justified.
- No debug steps (`log on`, `stop`, …) or commented-out scenarios left in.
- Outlines instead of copy-paste; scenario names unique in the file.

### 3. Feature-file context

- A Background change affects every scenario in the file — list them.
- A new scenario that duplicates an existing one, or one in `Deferred/`: ask why.
- Shared state: does the new code rely on `Context` values another scenario sets?

### 4. Code rules (always)

Run the `pr-review` checklist (or `/code-review high` when available) on the Java part of the diff,
`.feature`-only changes included. Verify each finding yourself against the code or the ticket, drop
what you cannot confirm (label it DROPPED), and merge the confirmed ones into this report.

### 5. Proof it ran

- The PR states the environment and the live-run result for the new / changed scenarios. "Not run"
  without a reason is a blocker.

## Report

In this order:

1. **Verdict**: Approve, Comment, or Request changes, with one line why.
2. **Acceptance-criteria mapping table**.
3. **Findings**, most severe first: `blocker` / `question` / `nit`, `file:line`, what is wrong, the
   concrete fix.
4. **Drafted comments**, ready to paste: one review-level comment for description-level findings,
   one inline comment per line finding. Short, in the reviewer's voice, no tool output pasted, no
   praise padding.

A blocker is anything that breaks a `scenario-creation` rule, leaves a criterion unchecked, asserts
nothing, leaves data behind on a shared env, leaks a secret, or leaves the PR without proof it ran.
Everything else is a question or a nit.

## Never

- Post, approve, or request changes yourself.
- Report a finding you have not checked against the code, the config, or the ticket.
- Review only the diff hunk of a `.feature` file.
- Paste a tool's raw output as a PR comment.
