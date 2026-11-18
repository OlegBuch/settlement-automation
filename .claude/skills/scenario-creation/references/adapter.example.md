# Adapter template

Copy to `adapters/<suite>.md` and fill in. Everything repo-specific belongs here; nothing in
`SKILL.md` or `references/` may name a path, a build command or an environment.

Delete the parenthetical hints when filling it in.

```markdown
# Adapter: <suite name>

## Stack

(runner, language, HTTP client, assertion library, how the suite is normally launched)

## Layout

- Features root: `<path>` and its folders
- Step-definition globs (glue): `<path/*.java>`
- Shared helpers / context / models: `<paths>`
- Generated / build output (never edit): `<path>`

## Step conventions

- Voice and parameter style, data-table shapes, where a new step goes

## Background, login and env guard

- Exact phrases for: reset context, log in (per API / role), restrict to an environment

## Placeholders and saved values

- Tokens resolved in data tables and where they are resolved

## Tags

- Tags in use and what they mean (or "none required")

## Config to search before using an ID / user / URL

- `<files>` and their structure; which environments exist

## Environment

- How the target environment is chosen, what credentials / network are needed,
  files the agent must never write

## Verify (run from `<dir>`)

| When            | Command |
| --------------- | ------- |
| Always          | `<compile>` |
| Always          | `<dry-run>` |
| With user's OK  | `<live run of the changed scenarios>` |

## Suite-specific exceptions

## Delivery (optional)

Branch rule, commit rule, PR target and description. Delete when the repo opens no PR.
```
