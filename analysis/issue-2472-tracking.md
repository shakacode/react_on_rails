# Issue #2472 Tracking Plan

- Issue: https://github.com/shakacode/react_on_rails/issues/2472
- Title: Improve uploadRaceCondition.test.ts to verify truly concurrent asset writes
- Status: Draft tracking PR opened to coordinate implementation work while issue #2472 remains open.

## Plan

1. Run the existing `uploadRaceCondition.test.ts` as-is, then re-run with the race-condition fix reverted, to confirm what the current
   `addBarrier()` coverage does and does not prove.
2. Update `uploadRaceCondition.test.ts` assertions with explicit write-order evidence (for example, request/write event recording) so
   concurrency expectations are objective and reproducible.
3. Validate with focused test runs and update related test comments/documentation as needed.

## Success Criteria

1. `uploadRaceCondition.test.ts` fails without the race-condition fix and passes with it.
2. The test proves same-bundle uploads serialize correctly under contention.
3. The test proves different-bundle uploads can still proceed concurrently (no global single-mutex regression).
4. Focused local test run and CI job for the updated test both pass.
