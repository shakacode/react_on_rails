# TDD Workflow

Use this workflow when skill invocation is unavailable. The authoritative
companion skill is at `skills/tdd/SKILL.md` in the source pack.

<!-- Keep this workflow in sync with `skills/tdd/SKILL.md`. -->

Use this workflow to move in small, verified behavior slices:

```text
RED -> GREEN -> REFACTOR -> repeat
```

## Core Loop

1. Choose one observable behavior.
   - For a bug fix, first express the reported failure as one failing regression test.
   - For a feature or behavior change, start with the smallest user-visible or public-interface behavior.
   - Prefer tests through public interfaces and real code paths over tests coupled to private implementation details.
2. RED: write one failing test.
   - Run the new test with the repo's narrowest relevant test invocation. Start from `.agents/bin/test` for the repo default, then narrow it using the repo's test framework convention when possible.
   - Confirm the test fails for the right reason: the missing behavior or reproduced bug.
   - If it fails because of a typo, missing import, bad fixture, or harness problem, fix the test setup before touching production code.
   - If it passes immediately, do not proceed to GREEN: the test describes existing behavior; tighten or replace it until you have watched the intended failure.
3. GREEN: write the smallest production change that makes that test pass.
   - Do not add production code before a failing test exists.
   - Do not add speculative behavior for future tests.
   - Rerun the same targeted test and confirm it passes.
4. REFACTOR: improve while green.
   - Remove duplication, clarify names, and simplify structure only with tests passing.
   - Rerun the targeted test after each meaningful refactor step.
5. Repeat with the next behavior.
   - Add one new failing test at a time.
   - Keep each cycle narrow enough that a failure clearly points to the current behavior.

## Guardrails

- Never refactor while RED.
- Never batch-write all tests before implementation; use vertical slices.
- Never claim a bug is fixed without evidence: prefer a regression test that failed before the fix and passes after it.
- Only when a direct automated regression test is not practical, document why, then use the closest useful local verification from `.agents/bin/test` or the relevant package test command to capture before and after behavior.
- Before handoff or PR creation, run `.agents/bin/validate` in addition to the targeted tests used during the loop.

## Before Pushing

- If the change affects a developer workflow, exercise that workflow with the repo's relevant local verification rather than relying only on unit tests.
- If the change affects app-facing behavior, do minimal manual verification through the repo's relevant local app or manual-test surface when appropriate.
- Try to run the same relevant local tests that CI would run for the changed area before pushing, then run `.agents/bin/validate`.

## Done

The loop is complete when each observable behavior specified in the task or issue has passing test coverage, or documented before-and-after closest-useful verification only when a direct automated regression test is not practical, and the pre-push validation passes clean. Report the behaviors implemented, the tests added, any fallback verification rationale and before/after result, and the result of the pre-push validation.
