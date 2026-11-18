# Skills

Reusable workflows for the agent, adapted from `app-bedrock-tvjs/.agents/skills` to this
Cucumber-JVM + REST Assured API suite. Each lives in `.claude/skills/<name>/SKILL.md`.

## Available skills

| Skill               | Trigger                                                                  | What it does |
| ------------------- | ------------------------------------------------------------------------ | ------------ |
| `commit`            | `/commit` or "commit these changes"                                      | Plans Jira-keyed commits, asks for approval, never stages `configuration.json` env switches, `ATLAS_SESSION_*` or `target/` |
| `github-pr`         | `/github-pr` or "create a PR"                                            | Fork workflow on GitHub Enterprise: branch from `upstream/develop`, push to `origin`, PR to `xplatform/settlement-automation` `develop`, description from a fixed template, compile + dry-run before pushing |
| `scenario-creation` | `/scenario-creation`, "cover ITAPPSIT-1234 with tests", editing a `.feature` or a step class | Plans internally, writes Gherkin that binds to real steps, placeholders and config, cleans up its data, verifies with compile + Cucumber dry-run (three passes), live run only with the user's OK. Repo specifics live in `adapters/settlement-automation.md` |
| `scenario-review`   | `/scenario-review <PR>` or "review this scenario PR"                     | Maps Jira acceptance criteria to scenario lines, checks the scenario-creation rules and the whole feature file, drafts comments. Read-only |
| `pr-review`         | `/pr-review` or "review my branch before I push"                         | Local review of the branch diff (incl. uncommitted) with a Java / Cucumber / shared-env checklist. Read-only |
| `refactor`          | "clean up / refactor this step class"                                    | Behaviour-preserving refactors of step defs, `Context`, `Utility`, models; step phrases treated as public API |
| `learn`             | `/learn pr <n>`, `/learn sweep`, `/learn prune`                          | Turns human review comments into lines in these skills / `CLAUDE.md`, or proposes removals |

### Test design (adapted from qa-harness)

| Skill / agent       | Trigger                                              | What it does |
| ------------------- | ---------------------------------------------------- | ------------ |
| `design-tests`      | `/design-tests ITAPPSIT-1234` or "design the tests for …" | Orchestrates the flow below and leaves `qa-design/features/<KEY>-<slug>/` |
| `collect-sources`   | `/collect-sources <KEY or page_id>`                  | Read-only Jira/Confluence walk via `mcp-atlassian`, link prioritization (`prioritize.py`), redacted snapshots, source manifest |
| `coverage-plan`     | `/coverage-plan <KEY>`                               | Risk register + P0–P3 coverage matrix with `[[MISSING_INFO]]` / `Q-xx` for anything unsourced (lean replacement for BMAD TEA) |
| `close-session`     | "save this to memory"                                | Proposes updates to `qa-design/knowledge/` cards, applies after approval |
| `extract-knowledge` | "build the memory from the existing features"        | Proposes cards from existing features / docs |
| agent `qa-reviewer` | used by `design-tests`, `scenario-review`            | Clean-context review of a coverage matrix or `.feature` files against cited sources; JSON findings |
| agent `api-endpoint-scanner` | used by `collect-sources`                   | Catalogs the routes a cloned service repo exposes, with `file:line` |

Flow: `design-tests` → `collect-sources` → `coverage-plan` → `qa-reviewer` → `scenario-creation` (Gherkin for
`ready` rows) → `qa-reviewer` → `close-session`. Setup and policies: `qa-design/README.md`.

Not ported from qa-harness (manual Xray only): `design-xray-cases`, `review-cases`, `review-ticket`,
`review-evidence`, `publish-xray`, `sync-guides`, `qa-test-planner`, BMAD / TEA.

Not ported (specific to the TV app): `player-bug-fix`, `player-repro`, `player-mock-context`,
`ds-component-upgrade`, `storybook-visual-stories`, `ts-migration`, `tvjs-canary-monitoring`.

## Chaining

`scenario-creation` asks for a delivery mode first (guided / autonomous) and, in autonomous mode,
ends by composing `commit` and `github-pr`. `scenario-review` uses `pr-review` for the Java part.
`learn` ends with `commit` + `github-pr`.

## Safety defaults shared by all skills

- Live scenario runs hit shared environments (`dev`, `devtest`, `preprd`): only with the user's
  explicit OK, on the env they name.
- Never write credentials, tokens or session values; never commit `configuration.json` `env` /
  `awsKeyset` switches, `ATLAS_SESSION_*`, `config/creds-alias.conf`, `config/*.local.json`.
- `gh` needs `GH_HOST=<GITHUB_HOST>` and the VPN.

## Adding a skill

A directory under `.claude/skills/` with a `SKILL.md`:

```yaml
---
name: skill-name
description: When and why to use this skill
---
```
