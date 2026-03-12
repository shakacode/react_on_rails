# Issue #2472 Tracking Plan

- Issue: https://github.com/shakacode/react_on_rails/issues/2472
- Title: Improve uploadRaceCondition.test.ts to verify truly concurrent asset writes
- Status: Draft tracking PR opened to coordinate implementation work while issue #2472 remains open.

## Plan

1. Run the existing `uploadRaceCondition.test.ts` as-is, then re-run with the per-bundle lock behavior in
   `packages/react-on-rails-pro-node-renderer/src/worker.ts` reverted in the `/upload-assets` handler (specifically the
   `lock(bundleFilePath)` / `unlock(lockfileName)` calls inside `copyPromises.map`), to confirm exactly what current
   `addBarrier()` coverage does and does not prove.
2. Add one new same-bundle upload-vs-upload contention case in `uploadRaceCondition.test.ts`, and augment the existing
   different-bundle upload-vs-upload cases with explicit overlap instrumentation (event markers around write start/end)
   so concurrency assertions rely on objective evidence, not timing heuristics alone.
3. Validate with focused test runs and update related test comments/documentation as needed.

## Success Criteria

1. A new same-bundle upload-vs-upload contention block is added, and existing different-bundle upload-vs-upload blocks are augmented
   with overlap instrumentation/assertions.
2. The same-bundle upload-vs-upload block fails when the upload-path `lock(bundleFilePath)` section is reverted and passes when restored.
3. The same-bundle block includes explicit write-order evidence (event markers/timestamps) proving serialization under contention.
4. The different-bundle blocks include objective overlap evidence (interleaved write markers for distinct bundle keys), with bounded
   timing checks as secondary guards, proving concurrent progress (no global single-mutex regression).
5. Focused local test run and the PR CI job covering these tests both pass.
