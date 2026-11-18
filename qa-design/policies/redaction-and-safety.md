# Redaction and safety

Adapted from qa-harness `guides/policies/redaction-and-safety.md`.

- Never copy into any file (snapshots, design packs, memory, features, steps, logs) API keys, tokens, passwords,
  session values, connection strings, personal emails or phone numbers. Replace them with `[REDACTED:<type>]` and
  note it in `sources/inline-security-redaction.md`.
- Never read `.env`, `ATLAS_SESSION_*`, `config/creds-alias.conf`, `config/*.local.json`, `~/.aws/credentials`,
  keys or certificates.
- Test data uses non-production, non-personal values. If a source only shows real customer data, describe its shape
  and mark the value `[[MISSING_INFO]]`.
- Every coverage row declares `env_risk` (Safe | Low | Medium | High) for running it on a shared environment
  (`dev`, `devtest`, `preprd`). High-risk rows (bulk deletes, re-creating settlements, changing shared reference data)
  are never planned against `prd` and need an explicit env guard and the user's OK to run.
- Jira and Confluence are **read-only** here. The MCP server runs with `READ_ONLY_MODE=true`; there is no write mode.
