---
name: refactor
description: 'Surgical refactoring of the settlement-automation Java code (step definitions, Context, Utility, model, RequestContainer) without changing what any scenario does. Use when asked to "clean up", "refactor", or "improve" code in this repo.'
source: app-bedrock-tvjs · .agents/skills/refactor (adapted to Java / Cucumber-JVM)
---

# Refactor

Improve code structure and readability without changing external behaviour. Here "behaviour" means:
every existing `.feature` binds to the same steps, sends the same requests and asserts the same
things. Gradual evolution, not revolution.

## Principles

1. **Preserve behaviour** — change how, not what. Step phrases are a public API: renaming or
   changing a regex breaks every `.feature` that uses it.
2. **Small steps** — one change, then compile + dry-run, repeat.
3. **The safety net is the dry-run plus a live run** of the scenarios touching the refactored
   code. Without a live run you have only proven binding, not behaviour — say so.
4. **One thing at a time** — never mix a refactor with new scenarios or a fix.
5. **Don't refactor** code that works and won't change, or "just because".

## Process

1. **Prepare** — find every usage: `grep -rn "<step phrase start>" src/main/resources` for steps,
   IDE/grep callers for methods. Note which feature files you will need to re-run.
2. **Identify** — the smell, the plan.
3. **Refactor** — one change; `mvn -q compile`; dry-run the affected features
   (command in `scenario-creation/adapters/settlement-automation.md`).
4. **Verify** — dry-run has no `undefined` / `ambiguous` steps; ask the user to live-run (or, with
   their go-ahead, run) the affected scenarios on the usual env.

## Code smells & fixes

### Long step method

Pull request building, calling and verification into helpers:

```diff
- @When("I POST a settlement with the following properties:")
- public void postSettlement(DataTable table) {
-     // 70 lines: map table, replace <tokens>, build body, call, parse, store ids, assert...
- }
+ @When("I POST a settlement with the following properties:")
+ public void postSettlement(DataTable table) {
+     HashMap<String, Object> props = toRequestProps(table);          // asMap + utility.replaceParmValues
+     request = RequestContainer.build().submitEntity(HttpOp.POST, EntityType.SETTLEMENT, props);
+     request.call(context.popExpectedStatus(201));
+     rememberCreatedIds(request);
+ }
```

(Illustrative: check the real `HttpOp` / `EntityType` constants and default status before
copying.)

### Duplicated token resolution / helpers

`<uuid>`, `<last-settlement-id>`, `<TagName>` resolution belongs in `Utility.replaceParmValues`
(or one shared helper). Delete private copies in step classes and call the shared one.

### Shared state in the wrong place

State that must survive across step classes belongs in `Context`, not in a `static` field of a step
class (it leaks between scenarios). State used by one class stays an instance field there.

### Large step class

Split by API resource or pipeline stage (`CrudSettlements`, `SettlementItemTimebound`, …), keeping
phrases unchanged. A move must not create a duplicate definition — the dry-run will say
`ambiguous`.

### Magic values

```diff
- if (attempts > 30) fail(...);  Thread.sleep(10000);
+ private static final int MAX_POLLS = 30;
+ private static final Duration POLL_INTERVAL = Duration.ofSeconds(10);
```

Environment-specific UUIDs (products, programs, orgs) go to `configuration.json` or stay in the
`.feature`, never in Java.

### Nested conditionals

Guard clauses / early returns; `Optional` instead of null checks chains.

### Primitive obsession

Use the existing enums and models (`EntityType`, `HttpOp`, `HttpStatus`, `RegistrationAdjective`,
`Settlement`, `SettlementItem`, …) instead of raw strings and `HashMap<String, Object>` where a model
already exists.

### Number / date comparisons

Use `BigDecimal.compareTo`, `Utility.areDoublesEqualEnough`, `Utility.areDatesEqual` /
`normalizeDateTime` instead of string equality on numbers or timestamps.

### Dead code

Unused helpers, imports, commented-out blocks. Git keeps the history. Leave `Deferred/` features
alone unless asked — they are parked on purpose.

## Checklist

- [ ] No step phrase / regex changed (or, if asked to, every `.feature` usage updated in the same change)
- [ ] Dry-run: no undefined / ambiguous steps
- [ ] `mvn -q compile` green, no new warnings
- [ ] No new static mutable state outside `Context`
- [ ] No duplicated helpers; shared ones in `Utility` / `RequestContainer`
- [ ] No environment IDs or secrets in Java
- [ ] Affected scenarios named for the live run
