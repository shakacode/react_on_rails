# P6 spike results: prerender → postponed → resume across processes (#4771)

Verified 2026-08-07 on react-dom **19.2.7** (the dummy app's installed version), Node 22.12,
via `./run-all.sh` (every step a separate OS process). Spec context: PR #4769
§Scenario B; this experiment closes research open question #3 and the review
amendment on priority ordering.

## Pass/fail versus the issue criteria

| Criterion                                                              | Result                                                                                                                         |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Prelude + `postponed` persisted to disk in process A                   | ✅ `prelude.html` (1567 B), `postponed.json` (1020 B) — plain JSON, survives `JSON.stringify`/`parse`                          |
| Resume in a **separate process invocation**                            | ✅ process B/C read `postponed.json` and produced the tail with `resumeToPipeableStream`                                       |
| Tail composed (a) appended client-side, (b) piped into original stream | ✅ both arms byte-identical for a Fizz stream (asserted), composed docs verified once                                          |
| Boundaries resolve from the resume stream                              | ✅ jsdom executes the inline `$RC` runtime: all 10 sections revealed, no visible skeletons, no hidden leftovers                |
| Boundaries **hydrate** from the resume stream                          | ✅ `hydrateRoot` on the composed document: zero recoverable hydration errors; all 10 counter buttons interactive (click 0 → 1) |
| Bytes ×1.0                                                             | ✅ every `SECTION-n-CONTENT` marker crosses the wire exactly once; no duplicate `B:`/`S:` ids                                  |
| Amendment: does emission order follow data-resolution order?           | ✅ **Yes.** Document-order resolution [3…9] → emission `B:[0…6]`; reverse resolution [9…3] → emission `B:[6…0]`                |

## Semantic findings (for the spec's verified-facts section)

1. **The pair works outside Next.js.** `prerenderToNodeStream` aborted at the
   shell yields a non-null `postponed`; a different process resumes it and the
   composed document reveals + hydrates. No renderer changes, no private APIs.
2. **Priority mechanism confirmed.** `resume` has no ordering option, but none
   is needed: boundary emission order tracks data-resolution order, not
   document order. A scroll-priority signal that reorders _data resolution_
   reorders _delivery_. The per-section-resume-units fallback contemplated by
   the amendment is **not required** for ordering (it may still be wanted for
   independent cache lifetimes — that's #4770's layer).
3. **Serialize `postponed` only after the prelude fully flushes** (react#36779:
   earlier serialization can hold stale segment ids). The scripts drain the
   prelude before `JSON.stringify`.
4. **Pause point needs no settle window if shell content is gate-only.** Fizz
   schedules prerender work as microtasks; with immediate sections resolving
   synchronously (pre-fulfilled thenables), a single queued macrotask
   (`setTimeout(0)`) is provably after all renderable work, so the abort is
   deterministic. Real data fetching in the shell would need
   `await Promise.all(shellData)` before aborting instead.
5. **Replay identity matters.** The resume re-renders components on the path
   to each hole and matches them by component name + key. The element tree
   passed to `resume` must be structurally identical to the prerender's
   (same names after minification, same keys) or React falls back to client
   rendering. The app module is shared byte-for-byte here; a renderer
   integration must guarantee the same bundle serves both phases.
6. **One re-pause limitation (upstream).** A carried-over hole that is still
   pending when a _resumed prerender_ aborts crashes
   (`It should not be possible to postpone at the root`,
   `replaySuspenseBoundary` creates boundaries with `tracked: null`). Not hit
   in this spike (live resume, never aborted) but it bounds multi-round
   prerender chaining; workaround exists (prune/graft the postponed state) if
   Scenario B ever needs it.

## Files

- `app.mjs` — shared 10-section app (3 immediate + 7 gated interactive counters)
- `prerender.mjs` — process A: pause at shell, persist prelude + postponed
- `resume.mjs` — process B: resume from disk; `--order=document|reverse` controls data-resolution order
- `verify.mjs` — composition checks (bytes ×1.0, ids, reveals) + jsdom `$RC` execution
- `hydrate.mjs` — `hydrateRoot` on composed doc + per-section click test
- `run-all.sh` — full pipeline; exits non-zero on any failure
