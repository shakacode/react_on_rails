# PPR Plan of Record

**Status:** Plan of record — consolidates all prior PPR planning documents
**Date:** 2026-08-13
**Consolidation issue:** [#4885](https://github.com/shakacode/react_on_rails/issues/4885)
**Implementation tracking:** [#3571](https://github.com/shakacode/react_on_rails/issues/3571) (Track B)
**Author of consolidation:** prepared for maintainer review under #4885; all owners
and dates in this document are **proposals** pending maintainer confirmation.

## Supersedes

This document is the single plan of record for Partial Prerendering (PPR). It
supersedes:

| Superseded doc                          | What it contributed                                                          |
| --------------------------------------- | ---------------------------------------------------------------------------- |
| `ppr-investigation-findings.md`         | 2026-05-18 research: two-layer architecture, `"use cache"`, hanging promises |
| `ppr-implementation-plan.md`            | Track B design of record; §Settle Criterion Design amended by #4855          |
| `react-19-partial-prerendering-plan.md` | Track A definition, React 19.2 verification checklist, #3255 decisions       |

All three were removed from the tree once their conclusions had been absorbed
here; every claim they carried that is still load-bearing is restated in this
document, and the bodies remain in git history (last present at `22d3cfdf6`).
The one decision that lived only in the third document is preserved below.

### Preserved from `react-19-partial-prerendering-plan.md`: #3486 decision record

Resolved 2026-06-03 by @justin808, closing the package-range questions split
out of #3255.

- **Minimum supported React version — React 18 (and 16/17) support stays.** The
  OSS `react-on-rails` and Pro `react-on-rails-pro` `react` / `react-dom` peer
  ranges stay at `>= 16` (verified still true on `origin/main`). v17 is a
  Ruby-baseline release, not a React-baseline release, and ships features for
  React 16/17 consumers (`react-on-rails/webpackHelpers`
  `reactDomClientWarning`). The React 19 baseline RSC requires is expressed at
  the RSC boundary through the **optional** `react-on-rails-rsc` peer, so
  non-RSC SSR/streaming users are not forced off React 18. The
  `packages/react-on-rails/src/ReactDOMServer.cts` React 16/17 shim therefore
  stays; removing it remains gated on an explicitly signed-off baseline bump.
- **The record's second clause is itself superseded.** It widened the
  `react-on-rails-rsc` peer to `>= 19.0.2 < 20.0.0`; PR #4672 later raised the
  floor to `>=19.2.1 <20.0.0`. See §3 fact 6 and §7 D3 for the current pin.

**Stale reference note:** issue #4885 names a fourth planning doc,
`internal/planning/ppr-plan-validity-review-2026-07-12.md`. That file does not
exist on `origin/main`, on any local or remote branch of this repository
(checked all `ppr`-named branches: `experimental-ppr-implementation`,
`worktree-ppr-implementation`, `ppr-prerender-resume-integration`,
`4852-ppr-define-settle-criterion-for-prerender-abort`,
`abanoub/4771-prerender-resume-spike`), or in GitHub code search. The reference
is stale; only the three documents above existed and are consolidated here.
Same class of stale reference: #4885's D6 text cites a
`loader-approach-gap-analysis.md`, which likewise exists nowhere in this
repository; §7 D6 describes the failure mode directly instead of citing it.

## Evidence base (linked, not superseded)

These are evidence, not plan. They stay as-is:

- [`internal/analysis/ppr-settle-criterion-findings.md`](../analysis/ppr-settle-criterion-findings.md)
  — Next.js source analysis + 15 experiments on React 19.2.8; experiment 8 is
  the proof that untracked real I/O is silently missed by timing-based aborts.
  The experiment scripts are preserved in
  [`internal/analysis/experiments/settle-criterion/`](../analysis/experiments/settle-criterion/)
  (recovered from the deleted #4852 research worktree; all 15 re-validated
  2026-08-31 on react-dom 19.2.8).
- [`internal/analysis/ppr-settle-by-example.md`](../analysis/ppr-settle-by-example.md)
  — 7 rules for which components reach the static shell.
- [`internal/analysis/ppr-rsc-payload-by-example.md`](../analysis/ppr-rsc-payload-by-example.md)
  — RSC payload lifecycle; the unclosing-stream trick.
- [`internal/analysis/experiments/multi-round-resume/`](../analysis/experiments/multi-round-resume/)
  — standalone scripts (stable React 19.2.8) behind §1.3's upstream bound:
  multi-round chaining works via progressive deepening;
  `multi-resume-test.jsx` is the repro for the carried-over-pending-boundary
  crash; the prune/graft surgery and parallel fan-out workarounds are
  verified.
- [`internal/analysis/ppr-spike-findings.md`](../analysis/ppr-spike-findings.md)
  — **ported 2026-08-13** from the closed `react_on_rails_rsc` PR
  [#194](https://github.com/shakacode/react_on_rails_rsc/pull/194) (branch
  `experimental-ppr-implementation`, SHA `4c27ec8`) before garbage collection.
  The only document describing the architecture we actually built: layer
  diagram, delimiter protocol, key design decisions, Production Readiness Gap
  table.
- P6 spike results — `react_on_rails_pro/spec/dummy/spike/prerender-resume/RESULTS.md`
  on PR [#4851](https://github.com/shakacode/react_on_rails/pull/4851) (open,
  CHANGES_REQUESTED; landing it is a child work item because this plan cites
  it and it is not yet on `main`).

---

## 1. The architecture we actually built

Three implementations exist; none shipped. The architecture below is the one
that runs end-to-end today as `/product/ppr` in the marketplace demo
(shakacode/react-on-rails-demo-marketplace-rsc#137, merged 2026-07-21), built
from PR [#4659](https://github.com/shakacode/react_on_rails/pull/4659)'s
branch (`ppr-prerender-resume-integration`) plus `react_on_rails_rsc` PR #194.
Full detail: [`ppr-spike-findings.md`](../analysis/ppr-spike-findings.md).

### 1.1 Two-phase, Fizz-level, component-scoped

This is **not** the Next.js model. There is no route-level PPR, no build-time
prerender, no `"use cache"` compiler transform. It is component-level
prerender/resume on stable React 19.2 APIs:

**Phase 1 — Prerender** (first request or warm-up):

1. Flight `renderToPipeableStream` renders the full RSC tree (standard path —
   the Fizz prerender needs a live Flight stream it can abort against, not the
   finalized Flight prerender output; see spike findings §5.5).
2. `createFromNodeStream` builds the React element tree.
3. Fizz `prerenderToNodeStream` with an `AbortController` yields
   `{ prelude, postponed }` — the HTML shell and an opaque, JSON-serializable
   `PostponedState` recording the unresolved Suspense boundaries.
4. Shell + `PostponedState` are cached **as a unit** in `Rails.cache` (they are
   structurally paired; mixing generations corrupts the resume).

**Phase 2 — Resume** (every request):

1. Cached shell is served immediately (near-zero TTFB).
2. Flight `renderToPipeableStream` re-renders with all props (dynamic data
   included); `createFromNodeStream` rebuilds the tree.
3. Fizz `resumeToPipeableStream(tree, postponedState)` streams only the
   dynamic holes; standard `$RC` reveal + hydration on the client — no
   PPR-specific client code.

```text
                      Prerender Path                    Resume Path
Server Components     App + static props                App + ALL props
Flight layer          renderToPipeableStream            renderToPipeableStream
SSR layer             createFromNodeStream              createFromNodeStream
Fizz layer            prerenderToNodeStream             resumeToPipeableStream
                      { prelude, postponed }            dynamic HTML chunks
                      cache (shell + PostponedState)    streamed into shell slots
Client                instant shell HTML  ─────────►    complete page + hydration
```

Ruby surface (spike): `ppr_react_component` helper + `:ppr_prerender` /
`:ppr_resume` render modes; JS surface:
`pprPrerenderServerRenderedReactComponent` /
`pprResumeServerRenderedReactComponent` wired through
`streamServerRenderedComponent` for tracker setup and error enrichment.

### 1.2 The delimiter protocol — and its planned replacement

The spike transmits shell + `PostponedState` in one stream, split at an
`<!--PPR_POSTPONED_STATE-->` HTML comment. This worked for the spike but is a
string scan over user-controlled HTML. The productized v1 moves
`PostponedState` onto **chunk metadata**: the node-renderer chunk metadata map
is already `Record<string, unknown>` and merged into the Ruby chunk hash, with
`payloadType` as precedent (child work item).

### 1.3 What the P6 spike added (PR #4851)

The P6 spike proved the riskiest mechanism in isolation, on **stable**
react-dom 19.2.7, with every step in a **separate OS process**:

- Prelude + `postponed` persisted to disk; resumed by a different process.
- Bytes ×1.0 — every content marker crosses the wire exactly once; no
  duplicate `B:`/`S:` ids; zero recoverable hydration errors; all 10
  interactive sections hydrate and respond.
- **Priority ordering:** boundary emission order tracks **data-resolution**
  order, not document order — a scroll-priority signal that reorders data
  resolution reorders delivery, with no per-section resume units required.
- `postponed` must be serialized only after the prelude fully flushes
  (react#36779).
- Replay identity: the resume tree must be structurally identical (component
  names post-minification + keys); the same bundle must serve both phases.
- Upstream bound: re-postponing a carried-over pending boundary crashes — a
  limit on multi-round chaining, not on v1's single prerender→resume cycle
  (repro:
  [`internal/analysis/experiments/multi-round-resume/`](../analysis/experiments/multi-round-resume/)).

### 1.4 Production Readiness Gap (remaining)

Must have: integration tests with real async Suspense boundaries producing
non-null `PostponedState`; graceful degradation on resume failure;
`PostponedState` versioning/validation; cache warm-up. Should have: hit/miss
observability; controlled benchmarks; corrupted-state auto-eviction; docs.
The spike's full table also lists React 19.2 stabilization, which D3/fact 6
resolves for the supported pair — not a current v1 blocker; the remaining
items stand.
Full table: [`ppr-spike-findings.md`](../analysis/ppr-spike-findings.md) §8.

---

## 2. Decision D1 — what is PPR v1?

**Resolved: sequence them. v1 productizes the spike; `"use cache"` is v2.**
This follows the recommendation in #4885, and the evidence supports it:

- The spike's Fizz-level, component-scoped PPR (`prerenderToNodeStream` →
  cache `{shell, PostponedState}` in `Rails.cache` → `resumeToPipeableStream`)
  already delivers the headline TTFB/LCP metric (#3245 measured ~5.9 s cold →
  ~0.16 s warm TTFB, ≈36×, in the Pro dummy) and needs **no compiler
  transform**.
- The full `"use cache"` model additionally removes per-request RSC/Flight
  work and unlocks the client-JS-reduction metric — on a v1 cache hit, every
  server component still re-executes to regenerate Flight data. That is a real
  cost, but it is not what the 17.2 headline requires.
- #3571 currently reads as "v1 is the whole 10-phase plan." It is not; the
  #3571 body rewrite is a child work item.

Everything below is organized around that split.

---

## 3. Corrected facts

Facts the previous plans and #3571 do not reflect, re-verified against
`origin/main` (SHA `018266189`) on 2026-08-13:

1. **The `"use cache"` compiler transform is not on the v1 critical path.**
   #4855 introduced `cacheRead(fn)` and `connection()` as explicit runtime
   APIs: _"React on Rails does not have a compiler transform for this purpose.
   The explicit wrapper is the equivalent mechanism… If we later add a
   `"use cache"` directive with compiler support, the wrapper becomes its
   compiled output."_ Old Phase 3 (~3 weeks + cross-repo + bound-arg
   encryption) moves entirely to v2.

2. **Fizz prerender/resume is no longer unproven.** The P6 spike (§1.3) shows
   it works outside Next.js, across OS processes, on stable React, with a
   working priority signal. Old Phase 6's risk discount is obsolete.

3. **#4581 is closed** (fixed by #4722, merged 2026-07-18; verified closed
   2026-07-18T06:29Z). The "active Track-A caching risk" in earlier reviews is
   gone. #4607 still lists it as an open 17.0.x must-fix — stale cross-reference
   (child work item; issue edits are out of this PR's scope).

4. **The CHANGELOG `unstable_cache` entry is factually wrong — now at line
   477** (issue #4885 cites line 563; the file has drifted since). The entry
   claims `unstable_revalidateTag(tag)`, a `POST /cache/revalidate-tag`
   endpoint, and `ReactOnRailsPro::RSCCache.revalidate_tag(tag)` shipped in
   #3325. Verified 2026-08-13: **none of those symbols exist anywhere in the
   tree** (`grep -rn unstable_revalidateTag packages/ lib/ react_on_rails_pro/lib/`
   → 0 hits; no `RSCCache` module). The same false claim is **duplicated in
   `docs/oss/upgrading/release-notes/17.0.0.md:92`** — both corrections are one
   child work item. Phase 7 has no JS-side implementation.

5. **`unstable_cache` has no user-facing usage documentation.** One mention
   exists in `docs/` — the 17.0.0 release-notes line above, which itself
   repeats the false revalidation claim. There is no guide, no API reference,
   despite `unstable_cache` and `registerCacheHandler` being publicly exported
   from `ReactOnRailsRSC.ts`.

6. **The D3 premise in #4885 is itself stale.** `rscPeerSupport.ts`
   (`packages/react-on-rails-pro-node-renderer/src/shared/rscPeerSupport.ts`)
   no longer carries two coordinated pairs with a 19.0.x default. Since PR
   #4672 ("Forward-port stable RSC 19.2.1 to main") the floor is
   `react-on-rails-rsc >= 19.2.1` with exactly **one** supported pair: rsc
   `19.2.x` ⇔ react/react-dom `>=19.2.7 <20`. The Pro package peer range is
   `react-on-rails-rsc >=19.2.1 <20.0.0`; the Pro dummy resolves React
   `~19.2.7`. `resumeToPipeableStream` **is available on every supported RSC
   configuration today.** See D3.

7. **The scroll-priority cluster (#4770–#4778) carries no `roadmap:17x` label
   and no milestone**, yet #4771 is the only empirical prerender/resume work
   in the repo. Labeling it onto the roadmap is a child work item. Separately,
   #4778's layered plan was superseded by #4835 / PR #4841, which eliminated
   its default transport.

8. **Nothing in CI measures TTFB or LCP today.** The Bencher pipeline tracks
   `rps`, `p50`, and `failed_pct` (p90/p99/max are deliberately untracked for
   noise reasons — `benchmarks/lib/bencher_runner.rb`), and route discovery
   skips `*_for_testing` routes
   (`benchmarks/lib/benchmark_routes.rb`, `return if path.include?("_for_testing")`),
   which excludes both existing streaming fixtures. The dedicated M1 runner
   exists (#4073, closed); the Bencher main gate re-enable is tracked in #3169
   (open). See §6.

9. **Public comparison concedes the capability.**
   `docs/pro/react-server-components/nextjs-comparison.md:201` lists "Static
   shell + streamed dynamic holes": Next.js → PPR; React on Rails Pro → "async
   props (related goal, different mechanism)". Updating it is part of the v1
   docs child item — only after v1 ships.

---

## 4. Re-cut phasing

### 4.1 Scorecard against the old 10-phase plan (~6 months)

| Old phase                           | Status today                                                                                                                                                     | Where it lands                       |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| 1. CacheHandler + LRU + adapter     | **Largely shipped** in #3325 (`unstable_cache`, `registerCacheHandler`, in-memory LRU; Redis/Tiered per release notes) — with known defects (§7 foundation list) | Hardening                            |
| 2. Runtime `cache()` wrapper        | Partially shipped (`unstable_cache`); no per-render RDC; hand-rolled `buildCacheKey`                                                                             | Hardening                            |
| 3. `"use cache"` transform          | **Not needed for v1** (fact 1)                                                                                                                                   | v2                                   |
| 4. CacheSignal + two-pass driver    | **Design complete** (#4855 + experiments); implementation not started                                                                                            | v2 (see D2)                          |
| 5. Hanging-promise Rails APIs       | Not started; `connection()` API designed                                                                                                                         | v2 (with D2)                         |
| 6. Fizz prerender + resume          | **Proven** (P6 spike, #4659, marketplace demo); not on `main`                                                                                                    | **v1 core**                          |
| 7. cacheLife/cacheTag/revalidateTag | Ruby tag system mature (`ReactOnRailsPro::Cache`/`TagIndex`/`Revalidates` on `Rails.cache`); JS side does not exist (fact 4)                                     | v1 uses Ruby tags; JS bridge v2 (D8) |
| 8. Client-reference threading       | Not started                                                                                                                                                      | v2                                   |
| 9. CDN resume protocol              | Parked (#3572)                                                                                                                                                   | Parked                               |
| 10. Docs/examples/migration         | Not started                                                                                                                                                      | Split v1/v2                          |

### 4.2 v1 — productize the spike (17.2 headline)

Work items are the child issues in §8 ("PPR v1" block). Effort, honestly:

| Work item                                                                | Estimate  |
| ------------------------------------------------------------------------ | --------- |
| Re-land prerender/resume pipeline with #4659 review defects fixed        | 2 weeks   |
| `PostponedState` → chunk metadata (drop in-band delimiter)               | 1 week    |
| `PostponedState` versioning + validation + graceful degradation          | 1 week    |
| Atomic paired shell+state storage + cache-key contract (no #4581 repeat) | 1 week    |
| **CSS/asset coordination between cached shell and resume stream (D6)**   | 2–3 weeks |
| Cache warm-up mechanism (D5)                                             | 1 week    |
| Hit/miss instrumentation and observability                               | 0.5 week  |
| Integration + E2E tests with real non-null `PostponedState`              | 1.5 weeks |
| Dummy-app cached-shell-plus-streamed-holes fixture                       | 0.5 week  |
| A/B benchmark (PPR vs SSR vs streaming SSR vs RSC) on the M1 runner      | 1 week    |
| Docs + migration guide + `nextjs-comparison.md` update                   | 1 week    |

**v1 total: ~12.5–13.5 engineer-weeks — roughly 3 months for one engineer,
~6.5–7 weeks with two (parallelism is imperfect).** The estimate is dominated by **D6 (CSS coordination)**, the
**pipeline re-land with its five known defects**, and the **test + benchmark
evidence chain** (which is most of what separates "works in a demo" from
"shipped three times zero times").

### 4.3 v2 — `"use cache"` (post-17.2, gated; see D1/D2/D7/D8)

| Work item                                                                                           | Estimate  |
| --------------------------------------------------------------------------------------------------- | --------- |
| CacheSignal + module-load tracking + settle budget (design done, #4855)                             | 2 weeks   |
| `cacheRead()` / `connection()` public APIs                                                          | 1 week    |
| Two-pass prerender driver                                                                           | 2 weeks   |
| Build-time `"use cache"` transform (cross-repo, D7)                                                 | 3 weeks   |
| `cacheLife`/`cacheTag`/`revalidateTag` on RSC-bytes layer + Ruby bridge (D8)                        | 2–3 weeks |
| Determinism guard (double-prerender diff; `Date.now`/`Math.random`/`crypto.randomUUID` build guard) | 1 week    |

**v2 total: ~11–12 engineer-weeks**, dominated by the cross-repo transform and
the invalidation bridge. Foundation-hardening items (§8) are shared
prerequisites and estimated there.

---

## 5. Public API surface (for review before it is built)

### 5.1 Helper

```ruby
ppr_react_component("ProductPage",
  props: { product: @product },
  cache_key: ["product", @product.id],
  cache_tags: ["product:#{@product.id}"],
  cache_options: { expires_in: 60.seconds }
)
```

- **Name:** `ppr_react_component` (Pro helper; established by #3245/#4659).
- **Options:** `props:` (standard), `cache_key:` (required — no implicit
  whole-props key), `cache_tags:` (top-level revalidation tags), and
  `cache_options:` reserved for `Rails.cache` write options (`compress`,
  `expires_in`, `race_condition_ttl`) — **the option contract follows the
  existing `cached_stream_react_component` convention** (rather than the
  spike's `cache_ttl:`/`tag_keys:` spelling), so
  `ReactOnRailsPro.revalidate_tag` evicts PPR shells exactly as D8 promises.
  Remaining `react_component` options pass
  through where meaningful; options that alter tree structure between phases
  are documented as forbidden (replay-identity constraint, §1.3).
- **Constraint surfaced in docs:** the same bundle (digest) must serve both
  phases; props that change tree structure must be identical in both phases;
  only data inside Suspense boundaries may differ.

### 5.2 Cache-key contract

`ReactOnRailsPro::Cache.react_component_cache_key` base (bundle digests —
deploys invalidate automatically) **plus** the caller's `cache_key:` **plus
the React version plus a PPR schema version**. React makes no cross-version
stability guarantee for `PostponedState` (D4), so the React version is part of
the key, and a schema-version field guards our own storage format. Shell +
`PostponedState` are stored as **one atomic record**; there is never a state
without its shell.

### 5.3 Behavior on every failure path

| Path                                                                                                            | Behavior                                                                                                                                                                                                                                   |
| --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Cache read error                                                                                                | Treat as miss; log; prerender.                                                                                                                                                                                                             |
| Miss; prerender OK; `postponed != null`                                                                         | Write paired entry atomically; serve shell; resume.                                                                                                                                                                                        |
| Miss; prerender OK; `postponed == null` (fully static)                                                          | **Must succeed** (a known #4659 defect raised here): cache complete shell; serve; skip resume.                                                                                                                                             |
| Miss; prerender fails before first flush                                                                        | **No cache write**; fall back to plain streaming SSR for this request; pre-flush failures keep real 4xx/5xx semantics (#3255 Decision 4).                                                                                                  |
| Miss; prerender partially fails (error inside a boundary)                                                       | **Must not cache** — `ppr_cache_miss` currently writes the shell unconditionally; a shell prerendered from a partially-failed tree must not be persisted (the #4581 class of bug). Serve this request's stream; re-prerender next request. |
| Hit; resume fails **before** the shell flushes (corrupt/stale `PostponedState`, replay mismatch caught on load) | Evict entry; **fall back to full streaming SSR in the same request**; instrument. The spike has no degradation here — this is a v1 must-have.                                                                                              |
| Hit; resume fails **after** the shell has flushed                                                               | Evict entry; **must not append a second document** — recovery is terminating the stream so the client retries (the next request is a structural miss); instrument.                                                                         |
| Hit; React version changed since prerender                                                                      | Key includes React version → structural miss; re-prerender.                                                                                                                                                                                |
| `resumeToPipeableStream` unavailable                                                                            | Clear config-time error (spike §5.7 guard). Cannot occur on the supported pin (fact 6) but the guard stays for mismatched installs.                                                                                                        |
| Consumer disconnects mid-stream                                                                                 | Existing consumer-abort support; fix the known defect where both cache paths discard `consumer_stream_async`'s return value (drops the resume stream's first chunk).                                                                       |

### 5.4 JS surface

`pprPrerenderServerRenderedReactComponent` / `pprResumeServerRenderedReactComponent`
remain internal (registered via `proStreaming.ts`). `cacheRead()` /
`connection()` (#4855) are the future public v2 APIs and are **not** shipped in
v1 (D2). `unstable_cache` / `registerCacheHandler` remain exported and gain
real documentation (§8 foundation item).

---

## 6. Acceptance metrics — buildable

Per #3255 Decision 5: **TTFB + LCP primary; response-end (full-stream
complete) and total transferred bytes secondary; client-JS reduction is a
v2-only metric** (v1 ships the same client bundle as normal SSR/streaming).

What must exist for these to be measurable (all child items in §8):

- **Fixture:** a Pro dummy route that caches a **shell** and streams **holes**.
  Today's `cached_stream_async_components_for_testing` caches the whole
  component; no cached-shell-plus-streamed-holes page exists to benchmark.
  The route must either avoid the `_for_testing` suffix or the harness must
  target it explicitly, because Bencher route discovery skips `*_for_testing`
  (fact 8).
- **Harness:** a ShakaPerf A/B gate under `test/shakaperf/ppr/` using the
  `perf` category (precedent: the `test/shakaperf/rsc-fouc` visreg gate),
  comparing the identical route as plain SSR vs streaming SSR vs PPR —
  control/experiment URLs held on the same delivery path within each pair
  (#3255 Decision 5). The marketplace demo's `measure-ppr-comparison.sh`
  remains the demo-level public artifact; the repo gate is the CI-facing one.
- **Runner:** the dedicated self-hosted M1 runner (#4073 — closed, runner
  exists). Bencher continues to track `rps`/`p50`/`failed_pct` for regression
  only; the main-gate re-enable is #3169 and is **not** a PPR dependency.
- **Pass target for the 17.2 headline:** PPR warm-hit TTFB ≤ 10% of the same
  route's streaming-SSR TTFB, LCP no worse than streaming SSR, measured on the
  A/B fixture on the M1 runner (the #3245 measurement, ≈36×, suggests large
  headroom; the gate is set conservatively and can be tightened with data).

---

## 7. Decisions D1–D9

Owners and dates are **proposals for maintainer confirmation** (review under
`merge_authority=ask`). "17.2" dates assume the current milestone cadence.

| #   | Decision                                | Resolution                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | Proposed owner                                       | Proposed date                              |
| --- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------------ |
| D1  | What is PPR v1?                         | **Resolved (§2):** v1 = productized spike (Fizz-level, component-scoped, `Rails.cache`); `"use cache"` = v2. #3571 body rewrite reflects this.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           | @AbanoubGhadban                                      | resolved in this plan                      |
| D2  | Settle criterion in v1                  | **Resolved:** v1 ships the fixed-timeout abort **with a documented contract**: shell data must be explicitly awaited before the abort (or be microtask-fast); real I/O that is neither is silently demoted to a hole (experiment 8). Detection: the double-prerender shell-diff guard runs in v1's integration tests — it catches nondeterministic timing variance only; deterministic real I/O past the cutoff produces the same shallow shell twice and passes undetected, so the explicit-await contract, not the guard, is the primary defense. `CacheSignal` + `cacheRead()` are v2 (gate below).                                                                                                                                                   | @AbanoubGhadban                                      | v1 ship (proposed 2026-10-15)              |
| D3  | React version / pin                     | **Resolved by events (fact 6):** PPR requires React 19.2+ (`resumeToPipeableStream`); since PR #4672 the only supported coordinated pair is rsc `19.2.x` (floor `>=19.2.1`) ⇔ react/react-dom `>=19.2.7 <20` — PPR is available on the current supported pin, no pin movement needed. Runtime guard stays. Remaining: close-out language on #3865 (still open) — child work item.                                                                                                                                                                                                                                                                                                                                                                        | @justin808 (pin authority)                           | with #3865 close-out (proposed 2026-09-01) |
| D4  | `PostponedState` durability             | **Resolved (§5.2/§5.3):** cache key versions on React version + bundle digest + PPR schema version. Stale/corrupt state detected before the shell flushes → evict + same-request fallback to full streaming SSR; detected after the shell has flushed → evict + terminate the stream (never append a second document; the client's retry is a structural miss). Hard failure is not acceptable.                                                                                                                                                                                                                                                                                                                                                          | @AbanoubGhadban                                      | v1 ship                                    |
| D5  | Cold start                              | **Resolved for v1:** first-request prerender stays the default (measured ~5.9 s cold in #3245 — acceptable once per key per deploy), **plus** a documented warm-up mechanism (background job / rake task hitting configured routes) as a v1 child item. Build-step prerender is deferred to the SSG track (#3891) with a stated gate: demand from a real Pro install.                                                                                                                                                                                                                                                                                                                                                                                    | @AbanoubGhadban                                      | v1 ship                                    |
| D6  | CSS in a cached shell                   | **Deferred-to-child with v1-blocking priority — the hardest unsolved item.** Prerender and resume are separate renderer requests with independent `RSCRequestTracker`/`injectRSCPayload` instances; the resume pass re-emits init scripts + CSS links into a page whose shell already declared them, and CSS-before-HTML flush order is the entire FOUC defense — a PPR page is the CRITICAL streamed-`$RC()`-reveal case: #4885's D6 rates it CRITICAL, citing a FOUC gap analysis not present in this repo (see Stale reference note). Child issue must produce a dedupe/coordination design (shared asset manifest between phases; resume pass suppresses links already in the shell) and prove it with the FOUC gate. Interacts #4557, #4049, #4474. | @AbanoubGhadban                                      | design proposed 2026-09-15; v1-blocking    |
| D7  | Where the `"use cache"` transform lives | **Deferred with v2 (gate: D1's v2 go-decision).** The directive transform belongs in the external `react-on-rails-rsc` package (delegates to React's vendored Flight node-loader) — cross-repo; sequencing interacts with #3497 (monorepo move: prefer transform work after any move to avoid double migration) and #4874 (Server Functions uses the same machinery).                                                                                                                                                                                                                                                                                                                                                                                    | @AbanoubGhadban                                      | gate: v2 go/no-go (proposed 2026-11-01)    |
| D8  | Tag-invalidation ownership              | **Resolved for v1:** PPR shells live **entirely in the Rails-cache namespace** — the mature Ruby `ReactOnRailsPro::Cache`/`TagIndex`/`Revalidates` system (`rorp:tag:v1:*`) already covers them (the spike used it via tags). **No JS bridge in v1.** The bridge to the JS byte cache (`rorp:rsc-cache:*`) is required only when `unstable_cache` entries participate (v2); until then `ReactOnRailsPro.revalidate_tag` not evicting `unstable_cache` entries is a documented limitation (part of the `unstable_cache` docs child item).                                                                                                                                                                                                                 | @AbanoubGhadban                                      | v1: resolved; bridge with v2               |
| D9  | Scroll-priority relationship            | **Resolved: shared foundation, separate lanes.** PPR v1 owns productizing prerender/resume; the scroll-priority cluster (#4770–#4778) consumes the same foundation and adds the data-resolution priority signal the P6 spike proved needs no per-section resume units. Labeling the cluster `roadmap:17x` + milestone is a child work item (issue edits out of this PR's scope). PR #4769 disposition (merge / re-scope against #4835 / close) is a named child decision.                                                                                                                                                                                                                                                                                | @AbanoubGhadban (lanes), @justin808 (roadmap labels) | proposed 2026-09-01                        |

---

## 8. Child-issue decomposition

> **To be opened by a follow-up batch — not opened by this PR.** Each child
> gets scope, acceptance criteria, and dependencies; all get linked as a
> checklist on #3571; all labeled `roadmap:17x` + `theme:performance` and
> milestoned. Two corrections named below — the CHANGELOG/release-notes fix
> and the #3571 body rewrite — are **child work items, not part of this PR**.

### Land the evidence first (already written, blocking)

- [ ] Land PR #4851 (P6 spike) — this plan cites its `RESULTS.md`, which is not on `main`
- [ ] Decide PR #4769 (scroll-priority design spec): merge, re-scope against #4835, or close (D9)
- [ ] ~~Port `ppr-spike-findings.md` out of closed `react_on_rails_rsc` PR #194~~ — **done in this PR** (`internal/analysis/ppr-spike-findings.md`)

### PPR v1 — productize the spike

- [ ] Re-land the prerender/resume pipeline with the #4659 review findings fixed. Known defects to carry: `postponed === null` must succeed rather than raise; `postponedState` must actually reach the resume function (Ruby sets `railsContext.pprPostponedState`, TS reads `options.postponedState`); PPR dispatch must not bypass the `isRSCBundle` branch in `resolve_render_function_name` (or a PPR render with RSC enabled calls a method the RSC bundle does not define); both cache paths currently discard `consumer_stream_async`'s return value, dropping the resume stream's first chunk
- [ ] Move `PostponedState` from the in-band `<!--PPR_POSTPONED_STATE-->` delimiter onto chunk metadata (`Record<string, unknown>` map, `payloadType` precedent) — the delimiter is a string scan over user-controlled HTML
- [ ] `PostponedState` versioning + validation + graceful degradation to full SSR on resume failure (D4)
- [ ] Shell + `PostponedState` atomic paired-artifact storage and cache-key contract (§5.2). Must not repeat the #4581 class of bug — `ppr_cache_miss` currently writes the shell unconditionally, caching shells from partially-failed trees
- [ ] CSS/asset coordination between the cached shell and the resume stream (D6 — v1-blocking design)
- [ ] Cache warm-up mechanism (D5)
- [ ] Cache hit/miss instrumentation and observability
- [ ] Integration + E2E tests with real async Suspense boundaries producing non-null `PostponedState` — the demo's own findings note it could not produce one
- [ ] Dummy-app fixture that caches a shell and streams holes (today's `cached_stream_async_components_for_testing` caches the whole component); must be reachable by the benchmark harness (fact 8)
- [ ] A/B benchmark: PPR vs SSR vs streaming SSR vs RSC on one route, ShakaPerf gate under `test/shakaperf/ppr/`, on the M1 runner (§6)
- [ ] Docs, migration guide, and the `nextjs-comparison.md:201` update

### Foundation hardening (needed by v1 and v2)

- [ ] Global handler registry — the module-scope `Map` in `cacheHandlerRegistry.ts` does not survive `vm.createContext`: every bundle version gets an empty registry, and a VM evicted by pool pressure silently drops every `registerCacheHandler` call plus the whole L1
- [ ] Memory/backpressure policy — the miss path buffers the entire payload with the tee's `push()` return values discarded; LRU caps at 1000 entries with no byte accounting
- [ ] Cache-key argument contract — `buildCacheKey.ts` is a hand-rolled serializer that throws on class instances, functions, symbols, and circular refs (so `children` and most non-plain props cannot be cached): reach `encodeReply` parity or document + enforce the supported subset
- [ ] Per-render Resume Data Cache — absent; the in-flight `Map` is process-lifetime dedup, not an RDC
- [ ] Document `unstable_cache` publicly (including the D8 limitation); fix the CHANGELOG entry (line 477 as of this writing; #4885 cited 563 pre-drift) **and** the duplicated claim in `docs/oss/upgrading/release-notes/17.0.0.md:92`

### PPR v2 — `"use cache"` (gated on D1's v2 go-decision)

- [ ] `CacheSignal` + module-load tracking + settle budget (#4855 design)
- [ ] `cacheRead()` / `connection()` public APIs
- [ ] Two-pass prerender driver
- [ ] Build-time `"use cache"` transform (cross-repo, D7)
- [ ] `cacheLife` / `cacheTag` / `revalidateTag` on the RSC-bytes layer + Ruby bridge (D8)
- [ ] Determinism guard: double-prerender shell diff + build-time `Date.now` / `Math.random` / `crypto.randomUUID` guard

### Tracking corrections (issue edits — child items, not this PR)

- [ ] Rewrite the #3571 body: checklist of the children above; remove the stale 10-phase table
- [ ] Fix stale cross-references: #4607 (#4581 is closed), #3891 and #3865 (both point at the dead #3245 gate), label the scroll-priority cluster onto the roadmap (D9)

### Already tracked — link, do not duplicate

#3485 (Turbo), #3865 (React 19.2 pin — see D3), #3885 (cacheSignal), #3891
(SSG on shells — D5 gate), #3572 (CDN edge-resume, parked), #4859
(payload-SSR synchrony test), #3169 / #4073 (benchmark gate + runner), #4557 /
#4049 / #4474 (CSS — D6).

---

## 9. Non-goals

- Writing PPR implementation code under #4885 — this document and the child
  issues are the deliverable; the children produce the code.
- Re-deciding the Track A / Track B split from #3255. That decision stands;
  this plan re-cuts phasing and sequencing underneath it. Track A (streaming
  SSR + fragment-cached shell on existing helpers) shipped its decisions in
  `react-19-partial-prerendering-plan.md` (removed; see Supersedes);
  this plan is Track B's plan of record.
- HTTP/CDN-caching of streamed responses with live per-request holes (#3255
  Decision 2 non-goal; CDN resume protocol stays parked in #3572).
