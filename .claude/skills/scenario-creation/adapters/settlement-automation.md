# Adapter: settlement-automation

## Stack

Cucumber-JVM 7 + REST Assured 5 + JUnit 5 assertions, Java 24, Maven. AWS SDK (Secrets Manager,
Lambda, SQS) and Postgres JDBC for pipeline / database checks. Features are run from IntelliJ
(Cucumber Java plugin, main class `io.cucumber.core.cli.Main`, glue `com.enernoc.bdap.stepdefs`).
There is no CI test run and no Maven test runner class.

## Layout

- Features root: `src/main/resources/` — one folder per API / component:
  `SettlementAPI/`, `SettlementMetadataAPI/`, `Settlement Creator API/`, `ECO/AdHocFinDataApi/`,
  `FinEngineApi/`, `Pipeline/{AESO,FCAS,IntervalCreator,Orchestrator,StmAndItemCreators}/`,
  `Performance/`, `Reference/`. `Deferred/` holds parked features — do not add to it or fix it
  unless asked.
- File names: PascalCase, `<Resource><Aspect>.feature` (e.g. `SettlementItemTimeboundAuthorization.feature`).
- Step definitions (glue): `src/main/java/com/enernoc/bdap/stepdefs/*.java`, one class per resource
  / pipeline area (`Common`, `CrudSettlements`, `SettlementItemTimebound`, `FullPipeline`,
  `CreatorLambdas`, `EcoAdhocFinancial*`, `CrudProductRule*`, `CrudRegistration*`, …).
- Shared: `src/main/java/com/enernoc/bdap/shared/` — `Context` (scenario state + config + secrets),
  `Utility` (placeholder resolution, date / number helpers), `AwsLambda`, `AwsSqs`,
  `AwsSecretsManager`, `PostgresClient`, `EPSClient`, `MomClient`, `EntityValidator`.
- Models: `src/main/java/com/enernoc/bdap/model/` — `RequestContainer` (builds and calls requests:
  `getEntity`, `getEntities`, `submitEntity(HttpOp, EntityType, props)`, `deleteEntity`,
  `call(HttpStatus)`), `EntityType`, `HttpOp`, `HttpStatus`, `UserCredentials`,
  `UserCredentialsEco`, entity models.
- Supporting data: `src/main/SQL_scripts/`, `src/main/Atlas_registration_extracts/`,
  `src/main/MetadataDB_registration_table/`.
- Docs: `Documentation/` (e.g. `FCAS.md` — FCAS data setup, preprd-only scenarios). Read it for
  the area you touch.
- Build output (never edit): `target/`.

## Step conventions

- First person: `I POST a settlement with the following properties:`, `I log in as …`,
  `the response should include the new settlement`.
- Cucumber expressions preferred (`{int}`, `{string}`, `{word}`); custom parameter types exist:
  `{userCredentials}`, `{ecoUserCredentials}`, `{entityType}`, `{httpOp}`, `{registrationAdjective}`.
  Grep `@ParameterType` before adding a new one — they are global across the glue package.
  Older steps use `^…$` regexes; do not convert them.
- Request bodies are two-column data tables (`field | value`) read with `asMap`; multi-row inputs
  use a header row read with `asMaps`.
- Put a new step in the class that owns the resource. Scenario state that another class needs goes
  in `Context` (`Context.getContext()`), not in a `static` field.
- Use the class `LOG` (slf4j), never `System.out`. Assertions via `org.junit.jupiter.api.Assertions`.

## Background, login and env guard (exact phrases)

```gherkin
Given I start with an empty context                     # always first; resets Context
And I log in as a settlement API admin                  # {userCredentials}: admin | user | prdadmin | no_product_access | no_stm_roles_user
Given I log in as an ECO ECO_ADMIN and get session      # {ecoUserCredentials}, see UserCredentialsEco
Given this scenario is only supported for the preprd environment
Given this scenario is not supported for the prd environment
```

Status expectation is set **before** the call, checked after:

```gherkin
And I expect the next API call to return a status code of 200 and message of "OK"
And I expect the next API call to return a status code of 404 and details of "No registration field history found"
...
Then the expected status should be returned
```

Polling: `I wait until {int} settlements have been processed by the pipeline`,
`I wait for the pipeline history row for the existing settlement with pipeline_step: {word} status: {word}`.
Fixed wait `I wait {int} seconds` exists — use only where no polling step fits.

Debug-only (never in a delivered scenario): `log on`, `log off`, `stop`,
`I want to turn on all logging`, `I stop here because {string}`.

## Placeholders and saved values

Resolved in data tables by `Utility.replaceParmValues` (`shared/Utility.java`):

- `<uuid>`, `<fixed-uuid>`, `<username>`, `<missing>` (field omitted — caller-specific)
- `<last-settlement-id>`, `<last-settlement-item-id>`, `<last-event-id>`, `<last-registration-id>`,
  `<last-pipeline-run-id>`, … (full list in the `switch`)
- `<product1..3>`, `<registration1..7>` (+ `-fa`, `-sdp`) — from `configuration.json` via `Context`
- any `<Tag>` saved earlier with `I save the {entityType} id for later use with the tag {word}`
  (or the other `I save …` steps) → `context.savedValues`

Grep the `switch` before using a token; an unknown `<Tag>` fails at run time with
"Saved values does not contain …".

## Tags

No tag is required and none is wired to a runner. Tags in use: `@preprd`, `@verification`
(scenarios that verify data a developer created in preprd), `@settlement_item_timebound`,
`@extra_checks`. Reuse these; add a new tag only when the request asks for one. Environment
restriction is done by the env-guard **step**, not by a tag.

## Config to search before using an ID / user / URL

- `configuration.json` — `env`, `awsKeyset`, per-env API URLs (`settlementApi`, `settlementMetadataApi`,
  `settlementCreatorApi`, `ecoApi`, `ecoExternalApi`, `finEngineApi`, `settlementItemTimeboundApi`,
  `atlas`, …), product / registration / organization / ITS mappings. Environments: `devtest`, `dev`,
  `preprd`, `prd`.
- `Context.java` static init — how those keys are read and which `Context.*` constants exist.
- Secrets (users, API keys) are read from AWS Secrets Manager at start-up. ECO usernames are in
  `configuration.json`; ECO passwords come from `shared/EcoCredentials.java` (env var
  `ECOUSERS_<ENV>_<KEY>_PASSWORD` → gitignored `config/eco-credentials.local.json` → secret
  `qaa-<env>`). Never copy a password anywhere else.
- Product / program UUIDs that appear literally in features (e.g. AESO in `Pipeline/AESO/*.feature`)
  are env-specific: reuse them only together with the same env guard.

## Environment

- Target env = `env` in `configuration.json`; AWS profile = `awsKeyset` (a key set in
  `~/.aws/credentials` holding a valid session). VPN required for every live run.
- Never write: `configuration.json` `env` / `awsKeyset` / credentials, `ATLAS_SESSION_*`,
  `config/creds-alias.conf`, `config/*.local.json`, `~/.aws/credentials`.
- A live run creates and deletes real data on a shared environment — run it only with the user's
  explicit OK, on the env they name.

## Verify (run from the repo root, Git Bash)

| When           | Command |
| -------------- | ------- |
| Always         | `mvn -q compile` (add `-o` when offline and deps are cached) |
| Always         | `mvn -q dependency:build-classpath -Dmdep.outputFile=target/cp.txt` (once per session / after pom change) |
| Always         | `java -cp "target/classes;$(cat target/cp.txt)" io.cucumber.core.cli.Main --dry-run --glue com.enernoc.bdap.stepdefs --plugin summary <changed .feature files>` — must show 0 undefined / ambiguous |
| With user's OK | Same command without `--dry-run`, plus `--name "<scenario name regex>"` to limit it, against the env in `configuration.json`; or the user runs the scenario from IntelliJ |

Notes: the classpath separator is `;` on Windows (`:` elsewhere). Quote feature paths with spaces
(`"src/main/resources/Settlement Creator API/…"`). The dry-run does not load secrets or call any API.

## Suite-specific exceptions

- Pipeline "re-create" scenarios (`Pipeline/AESO/E2E.feature`, FCAS) intentionally delete and rebuild
  settlements for a product / month on preprd. They are the only scenarios allowed to touch data
  they did not create, and only behind `this scenario is only supported for the preprd environment`.
- Several older features use fixed waits after lambda / SQS calls. Do not copy that into new
  scenarios when a polling step exists.

## Delivery

- Branch from `upstream/develop`: `<JIRA-KEY>-<Short-Hyphenated-Description>`
  (e.g. `ITAPPSIT-4292-Add-new-settlement-item-time-timebound`); no ticket → `ITAPPSIT-0000-<…>`.
- Commit with the `commit` skill (Jira-keyed imperative message, no agent attribution, never stage
  `configuration.json` env switch / `ATLAS_SESSION_*` / `target/`).
- Push to `origin` (the fork), open the PR with the `github-pr` skill against
  `xplatform/settlement-automation` `develop` (`GH_HOST=<GITHUB_HOST>`).
- PR description: the `github-pr` template; "Live run" states the env and result or "not run".
- A later review comment: fix in a new commit on the same branch, re-run the static verify set,
  answer the thread with what changed.
