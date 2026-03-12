# Issue #2472 Tracking Plan

- Issue: https://github.com/shakacode/react_on_rails/issues/2472
- Title: Improve uploadRaceCondition.test.ts to verify truly concurrent asset writes
- Status: Draft tracking PR opened to coordinate implementation work while issue #2472 remains open.

## Plan

1. Run the existing `uploadRaceCondition.test.ts` as-is, then re-run with the per-bundle lock behavior in
   `packages/react-on-rails-pro-node-renderer/src/worker.ts` reverted in the upload path (the `lock(bundleFilePath)` section), to
   confirm exactly what current `addBarrier()` coverage does and does not prove.
2. Add explicit upload-vs-upload concurrency cases in `uploadRaceCondition.test.ts`: one same-bundle case (new) and one
   different-bundle case (new). Keep the existing cross-endpoint render+upload same-bundle case as a baseline, then add
   explicit write-order evidence so concurrency expectations are objective and reproducible.
3. Validate with focused test runs and update related test comments/documentation as needed.

## Success Criteria

1. New upload-vs-upload test blocks are added in `uploadRaceCondition.test.ts` for both same-bundle and different-bundle contention.
2. The same-bundle upload-vs-upload block fails when the upload-path `lock(bundleFilePath)` section is reverted and passes when restored.
3. The same-bundle block includes explicit write-order evidence (event markers/timestamps) proving serialization under contention.
4. The different-bundle block includes bounded overlap assertions proving concurrent progress (no global single-mutex regression).
5. Focused local test run and the PR CI job covering these tests both pass.
