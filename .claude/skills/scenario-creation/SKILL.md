---
name: scenario-creation
description: >
  Create or extend Cucumber (Gherkin) scenarios and feature files for the settlement-automation
  API / pipeline suite (Cucumber-JVM + REST Assured + JUnit 5). Trigger when the user asks to write,
  add, or generate a scenario, a feature, or a `.feature` file, to cover a Jira ticket
  (ITAPPSIT-/BDAP-) with tests, or when editing `src/main/resources/**/*.feature` or
  `src/main/java/com/enernoc/bdap/stepdefs/*.java`.
version: 1.0.0
source: app-bedrock-tvjs · .agents/skills/scenario-creation (adapted for an API suite)
---

# Scenario creation

Produces Gherkin that binds to real step definitions, reuses real config values and helpers, cleans
up after itself on shared environments, and passes the suite's verify commands — with no invented
steps, tags, IDs or expected values.

`SKILL.md` and `references/` are **suite-agnostic**. Everything repo-specific (paths, commands,
environments, login steps, IDs) lives in an **adapter** under `adapters/`. The `version:` and
`source:` above let you diff this copy against the origin later.

## Pick the adapter first

List `adapters/` and pick the one whose **Layout** section contains the files the task touches.
Today there is one: `adapters/settlement-automation.md`.
If no adapter matches, or more than one could, **ask** — do not guess a layout.

## Workflow — plan, implement, verify, deliver

The order is mandatory. Do not use a tool's plan mode. Nothing is written before the internal plan
is complete. The plan is not shown, and nobody in the chat approves it.

Before any write, ask how to deliver, unless the prompt already says which:

1. **Guided** — the user reviews each diff, runs the live scenarios, and opens the pull request.
2. **Autonomous** — implement, verify statically, then commit, push and open the pull request
   following the adapter `Delivery` section. A live run against a shared environment still needs the
   user's explicit go-ahead (it writes data other people see).

### 1. Plan (no writes)

Do not create or edit `.feature`, step-definition, model or config files yet. Read, in this order:

1. `references/rules.md` — hard constraints
2. `references/patterns.md` — scenario and file shape
3. `references/suite-mechanics.md` — what makes a scenario runnable and safe on a shared env
4. the adapter

Then gather evidence — do not rely on memory:

- **Requirement**: when a design pack exists (`qa-design/features/<KEY>-*/03_coverage-matrix.md`,
  produced by `design-tests`), it is the requirement: write scenarios for its `ready` rows only, take
  expected values from the row and its cited source, put the row ID in a comment line directly above
  each `Scenario:` (`# ITAPPSIT4292-TB-001`), and never write a `blocked` row. Without a pack: the Jira
  ticket / acceptance criteria / API spec the user gave. Endpoints, fields, status codes and error
  messages come from there or from the API itself, never from guesses. Missing → ask.
- **Steps**: grep the adapter's step-definition globs for each action and assertion. Copy candidate
  phrases exactly, character for character, including how parameters and data tables are shaped.
- **Placeholders and saved values**: find how the suite resolves tokens like `<uuid>` or
  `<last-…-id>` and saved tags (adapter → Placeholders). Use only tokens that exist.
- **Config values**: IDs, users and URLs the scenario relies on — grep the adapter's config files
  and record `file:line`. They are plain strings resolved at runtime; **the dry-run will not catch a
  wrong ID**, so this grep is the only check before a live run.
- **Environment**: which environments the data exists in. Data that only exists in one env →
  the scenario declares that with the adapter's env-guard step.
- **File**: create vs extend; check the `Feature:` name is not already used in the suite.

### 2. Implement the internal plan

Write the Gherkin inside the suite the adapter names. Add a step definition only when the plan marked
it **new** because no existing phrase, or combination of them, can do the job. No extra scenarios, no
drive-by edits.

### 3. Verify

Run the adapter's **static** verify set (compile + Cucumber dry-run). One attempt is one full pass;
three passes in total. A green pass stops. While fewer than three passes have run, fix and start
another. After the third red pass, stop fixing and report the real output.

Then the **live** run of the new / changed scenarios on the target environment: in guided mode the
user runs it; in autonomous mode run it only after the user said yes in this conversation. Report the
environment, pass/fail and the first failing step with its message. A live failure caused by the API
(a real bug) is a finding to report, not something to "fix" by weakening the assertion.

### 4. Deliver

Autonomous mode with an adapter `Delivery` section: follow it after a green static pass (or after the
third red pass, with the failure stated). Guided mode: stop after verify, report the verify output and
the diff. No `Delivery` section: stop and report. Do not invent a pull request.

## Never

- Skip the internal plan, or write files while gathering evidence for it.
- Claim a step phrase, placeholder or config value exists without having grepped it.
- Invent an endpoint, field, status code, error message or expected number.
- Add a near-duplicate of an existing step, or a new step when existing ones already do the job.
- Leave created data behind on a shared environment, or delete data the scenario did not create.
- Ship a scenario that is disabled, commented out, or ends with `stop` / `This scenario fails because`
  to make the change go green.
- Write passwords, API keys, tokens or session values into features, steps or config.
- Change `configuration.json` `env` / `awsKeyset` as part of the change.
- Edit anything outside the suite the adapter names. Scenario creation does not change the APIs under
  test.
