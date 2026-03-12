# Issue #2472 Tracking Plan

- Issue: https://github.com/shakacode/react_on_rails/issues/2472
- Title: Improve uploadRaceCondition.test.ts to verify truly concurrent asset writes
- Status: Draft tracking PR opened to coordinate implementation work while issue #2472 remains open.

## Plan

1. Reproduce current test behavior and confirm where existing `addBarrier()` synchronization still allows serialized writes.
2. Update `uploadRaceCondition.test.ts` assertions to prove truly concurrent write paths and verify resilience under contention.
3. Validate with focused test runs and update related test comments/documentation as needed.

## Success Criteria

1. `uploadRaceCondition.test.ts` fails without the race-condition fix and passes with it.
2. The test asserts concurrent write behavior explicitly (not only eventual file correctness).
3. Focused local test run and CI job for the updated test both pass.
