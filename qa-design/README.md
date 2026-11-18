# qa-design — source-grounded test design for settlement-automation

Adapted from the **qa-harness** starter. The original designs manual Xray test cases; here the same front-end
(Jira/Confluence sources → risks → P0–P3 coverage → open questions → memory) feeds the existing
`scenario-creation` skill, which writes Cucumber scenarios.

## Layout

```
qa-design/
  policies/            sources of truth, [[MISSING_INFO]], redaction, language/format — always apply
  config/atlassian.env Jira/Confluence URLs, project + space filters, mcp-atlassian version (no secrets)
  features/<KEY>-<slug>/   one design pack per ticket (see .claude/skills/design-tests)
  knowledge/           shared memory: index.md, features/, components/, trusted-sources.yaml, _templates/
  scripts/run_mcp_atlassian.py   read-only MCP launcher (started by /.mcp.json)
  scripts/hooks/session_start.py injects knowledge/index.md at session start
  tools/sources/prioritize.py    link prioritization (P1 > P2 > P3)
  tools/confluence/versions.py   which Confluence pages changed since a design used them
  tools/tests/                   tests for the tools
```

Skills: `.claude/skills/{design-tests,collect-sources,coverage-plan,close-session,extract-knowledge}`.
Agents: `.claude/agents/{qa-reviewer,api-endpoint-scanner}.md`.

## Setup (Windows, macOS or Linux)

1. Python 3.11+ and `uv` (`uvx` starts `mcp-atlassian` 0.23.1 on demand).
2. Create Personal Access Tokens in Jira and Confluence (profile → Personal Access Tokens; read access is enough).
3. Put them in the repo-root `.env` (already created locally, gitignored; template in `.env.example`):
   ```
   JIRA_PERSONAL_TOKEN=...
   CONFLUENCE_PERSONAL_TOKEN=...
   ```
   Never paste tokens into the chat or any tracked file. The agent is denied read access to `.env`.
4. Connect to the VPN, start Claude Code from the repo root, approve the `mcp-atlassian` server when asked, and check
   `/mcp` shows it connected.
5. Optional checks:
   ```
   uv run --no-project --with pytest --with pyyaml pytest qa-design/tools/tests -q
   uv run qa-design/tools/confluence/versions.py memory
   ```

## Safety

- Read-only: the MCP server runs with `READ_ONLY_MODE=true` and only read tools enabled. There is no write mode.
- Confluence spaces outside `CONFLUENCE_SPACES_FILTER` are never read; extend the filter in `config/atlassian.env`
  only for spaces your team is allowed to use.
- Snapshots are redacted (`policies/redaction-and-safety.md`). Design packs and memory are committed and reviewed
  through PRs like any other change.

## Provenance

Ported and adapted from qa-harness: policies, `collect-sources`, `design-tests`, `close-session`,
`extract-knowledge`, `qa-reviewer`, `api-endpoint-scanner`, `prioritize.py` (+ tests), `versions.py`, the
session-start hook, knowledge templates, and the API part of `qa-test-design-patterns`. qa-harness `VENDORED.md`
states that `qa-test-design-patterns` and `api-endpoint-scanner` contain internally adapted material whose
redistribution rights are not established — confirm you may use them in this repository before committing.
