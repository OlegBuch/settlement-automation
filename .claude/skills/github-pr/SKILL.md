---
name: github-pr
description: Create and manage pull requests for settlement-automation using `gh` on GitHub Enterprise (fork → xplatform/settlement-automation, base `develop`). Trigger when the user wants to create or update a PR, describe a PR, push a branch, check PR status, or do any GitHub operation for this repo.
source: app-bedrock-tvjs · .agents/skills/github-pr (adapted)
---

# GitHub Workflow

Use `gh` for all GitHub operations. This repo lives on GitHub Enterprise, so every command needs
the host:

```bash
export GH_HOST=<GITHUB_HOST>        # or prefix each gh command with it
```

`gh auth login --hostname <GITHUB_HOST>` must already be done. The host is only
reachable on the corporate network / VPN: if `gh` times out, tell the user to connect and stop —
do not retry in a loop.

## Remotes — fork workflow

| Remote     | Repo                                   | Use                     |
| ---------- | -------------------------------------- | ----------------------- |
| `origin`   | `<user>/settlement-automation` (fork)  | push branches here      |
| `upstream` | `xplatform/settlement-automation`      | PR target, base `develop` |

Check with `git remote -v`; do not assume the names if they differ.

## Creating a Pull Request

First check whether the branch and PR already exist
(`gh pr list -R xplatform/settlement-automation --head <branch>`). If so, skip to the description.

1. **Branch** from the latest `upstream/develop` if not already on a feature branch:
   ```bash
   git fetch upstream
   git switch -c ITAPPSIT-4292-Add-settlement-item-timebound upstream/develop
   ```
   Name: `<JIRA-KEY>-<Short-Hyphenated-Description>` (the repo convention, e.g.
   `ITAPPSIT-4233-Adhoc-Financial-endpoints`). No ticket → `ITAPPSIT-0000-<Description>`.
2. **Run the quality checks** below. Fix what fails before pushing.
3. **Commit** with the `commit` skill.
4. **Push** to the fork: `git push -u origin <branch>`.
5. **Create the PR** against upstream:
   ```bash
   gh pr create -R xplatform/settlement-automation --base develop \
     --head <fork-owner>:<branch> --title "<JIRA-KEY> <summary>" --body-file <file>
   ```
   Add `--draft` when not ready for review. Then write the description as below.

## Quality checks

Run from the repo root (see `scenario-creation/adapters/settlement-automation.md` for details):

```bash
mvn -q compile                                         # step defs / model compile
mvn -q dependency:build-classpath -Dmdep.outputFile=target/cp.txt
java -cp "target/classes;$(cat target/cp.txt)" io.cucumber.core.cli.Main \
  --dry-run --glue com.enernoc.bdap.stepdefs --plugin summary <changed .feature files>
```

The dry-run must report no `undefined` / `ambiguous` steps. It does not call any API.
A live run of the changed scenarios needs AWS credentials, VPN and the right `env` in
`configuration.json`, and it writes data to a shared environment — the user runs it, or you run it
only after they say so. Report which environment it ran against.

## Writing a PR Description

There is no `.github/PULL_REQUEST_TEMPLATE.md` in this repo. Use this structure:

```markdown
## Jira
<link, e.g. <JIRA_URL>/browse/ITAPPSIT-4292> (omit if none — never invent)

## Why
<what behaviour of the Settlement / Metadata / Creator / ECO / FinEngine API or pipeline this covers, and why now>

## What changed
- Feature files: <path> — <scenarios added / changed>
- Step definitions / model / shared: <class> — <what and why>
- Config / SQL scripts: <if any>

## How to run
- Environment(s): <dev | devtest | preprd> (`env` in configuration.json)
- Scenarios: <feature path + scenario names>
- Preconditions: <data setup, preprd-only, Atlas hierarchy, …>

## Results
- `mvn compile`: ✅/❌
- Cucumber dry-run: ✅/❌ (<n> scenarios, <n> steps)
- Live run on <env>: ✅/❌/not run — <summary, failing step if any>
```

Steps:

1. **Identify the PR**: `$ARGUMENTS` if given, else `gh pr view --json url,number,title,state`
   for the current branch, else list open PRs (`gh pr list -R xplatform/settlement-automation
   --limit 10`) and ask which.
2. **Gather**: `gh pr diff <n>`, `gh pr view <n> --json commits,baseRefName,url,title`.
   Read files the diff references but does not show (e.g. the step class behind a new phrase).
3. **Analyse**: which APIs / pipeline stages are exercised, which environments the scenarios
   assume, new shared state in `Context`, cleanup, anything that changes existing scenarios.
4. **Run the quality checks** and note any you could not run.
5. **Generate the description.** Use only information you have. Do not make up results: a live run
   you did not see is "not run".
6. **Show the description and wait for approval.** Do not call `gh pr edit` before the user
   approves. Revise and re-show on request.
7. **Update the PR** after approval: `gh pr edit <n> -R xplatform/settlement-automation --body-file <file>`.
8. **Check the title**: `<JIRA-KEY> <summary>` (repo convention); update if needed.

## Reviewing & status

```bash
gh pr view 95 -R xplatform/settlement-automation
gh pr diff 95 -R xplatform/settlement-automation
gh pr checks 95 -R xplatform/settlement-automation      # if any checks are configured
gh pr list -R xplatform/settlement-automation --author @me
```

```bash
# All review threads of a PR
cat << 'EOF' | gh api graphql --input -
{
  "query": "query($owner: String!, $repo: String!, $pr: Int!) { repository(owner: $owner, name: $repo) { pullRequest(number: $pr) { reviewThreads(first: 100) { nodes { isResolved isOutdated comments(first: 100) { nodes { body author { login } path line outdated } } } } } } }",
  "variables": { "owner": "xplatform", "repo": "settlement-automation", "pr": {number} }
}
EOF
```
