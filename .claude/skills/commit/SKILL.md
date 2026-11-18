---
name: commit
description: Commit changes in settlement-automation with the repo's Jira-keyed message style. Trigger on `/commit` or "commit these changes".
source: app-bedrock-tvjs · .agents/skills/commit (adapted)
---

# Commit Changes

You are tasked with creating git commits for the changes made during this session.

IMPORTANT: DO NOT COMMIT ANYTHING THAT WAS NOT APPROVED BY THE USER.

## Process

1. **Think about what changed:**

   - Review the conversation history and understand what was accomplished
   - Run `git status` and `git diff` to see the modifications
   - Consider whether changes should be one commit or multiple logical commits
     (e.g. new step definitions + the `.feature` that uses them belong together; an unrelated
     model fix does not)

2. **Plan your commit(s):**

   - Identify which files belong together
   - Draft messages in the repo style (see below)
   - Focus on why the change was made, not just what

3. **Present your plan to the user:**

   - List the files for each commit
   - Show the commit message(s)
   - Ask: "I plan to create [N] commit(s) with these changes. Shall I proceed?"

4. **Execute upon confirmation:**
   - `git add` specific files only — **never** `git add -A`, `git add .` or `git commit -a`
   - Create the commits
   - Show the result with `git log --oneline -n [number]`

## Files that must not be committed unless the user explicitly says so

The working tree of this repo normally contains local-only files that are **not** gitignored:

| File / path                       | Why                                                                                         |
| --------------------------------- | ------------------------------------------------------------------------------------------- |
| `configuration.json`              | Tracked, but the local copy usually only switches `env` / `awsKeyset`. Committing that flips the target environment for everyone. Commit it only for a deliberate config change (new URL, new key), and then stage only those hunks (`git add -p` is interactive — ask the user to stage it, or edit a clean copy). |
| `ATLAS_SESSION_*`                 | Live Atlas session tokens (gitignored). Never force-add.                                    |
| `config/creds-alias.conf`, `config/*.local.json` | Okta settings and ECO passwords (gitignored). Never force-add.               |
| `target/`, `.idea/`, `.continue/` | Build output / IDE / local assistant config (gitignored).                                   |

Never add a password, API key, token or session value to any committed file, including
`configuration.json`. ECO passwords are resolved by `shared/EcoCredentials.java` (env var →
`config/eco-credentials.local.json` → AWS secret `qaa-<env>`); everything else is in AWS Secrets
Manager (see `README.md`).

## Message style

The history uses short imperative messages that carry the Jira key when there is one:

```
ITAPPSIT-4292 Add tests for settlement item timebound feature
ITAPPSIT-4275 Add new ECO financial fields to Financial.feature
Update AESO tests with new DST timing
```

- First line: `<JIRA-KEY> <imperative summary>`, ≤ 72 chars. Keys used here: `ITAPPSIT-<n>`,
  `BDAP-<n>`. No key known → plain imperative summary; never invent a key.
- Optional body (blank line first): what changed and why — which API / pipeline step, which
  environment the scenarios target (`dev`, `preprd`, …), anything a reviewer must know to run it.
- Take the key from the branch name (`ITAPPSIT-4292-Add-...`) or the conversation.

## Important

- **NEVER add co-author information or agent attribution**
- Commits are authored solely by the user
- No "Generated with Claude" or other agent attribution messages
- No "Co-Authored-By" lines
- Write commit messages as if the user wrote them
- Ask the user for approval before committing

## Remember

- You have the full context of what was done in this session
- Group related changes together
- Keep commits focused and atomic when possible
