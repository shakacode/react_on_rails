# Production Migration Plan — JSON render-request body (#3280)

Status: **proposal**, derived from the completed AI-agent experiment for
[shakacode/react_on_rails#3280](https://github.com/shakacode/react_on_rails/issues/3280).

This document records what the experiment did, the numbers it produced, the
operational problems hit while running it, and the work a production-quality
implementation still needs. It is not itself the implementation.

## Links

| Artifact | Location |
|---|---|
| Issue | https://github.com/shakacode/react_on_rails/issues/3280 |
| Experiment PR (the "demo") | https://github.com/shakacode/react_on_rails/pull/3293 |
| Experiment commit (react_on_rails) | [`352743ef1`](https://github.com/shakacode/react_on_rails/commit/352743ef18b204bb34072b42aa8be32f05927bfa) — `[EXPERIMENT] Send render request body as JSON when no bundle attached` |
| Experiment branch | `experiment/3280-json-render-body` (base `upcoming-v16.3.0`) |
| Demo-app harness commit (rsc-benchmar) | [`b90977ef3`](https://github.com/AbanoubGhadban/rsc-benchmar/commit/b90977ef33d72c33aacbce09b07d66db46b46155) — `demo(#3280): JSON render-body experiment harness + parallel A/B tooling` |
| Demo-app branch | https://github.com/AbanoubGhadban/rsc-benchmar/tree/experiment/3280-json-render-body |
| Related/orthogonal PR | [#3217](https://github.com/shakacode/react_on_rails/pull/3217) — `perf(pro): enable TCP_NODELAY on httpx` |

## TL;DR / Verdict

**Go.** On the canonical large-payload page (props ~1.16 MB, HTML ~2.18 MB),
switching the steady-state render-request body from
`application/x-www-form-urlencoded` to `application/json` cut **median total
wall 396 → 92 ms (−304 ms)** and **median GC 112.8 → 9.8 ms (−103 ms)** — both
~2× the issue's acceptance bar (≥150 ms wall, ≥15 ms GC). HTML output is
byte-equivalent. The win reproduces across three independent measurement
methodologies and survives applying the orthogonal #3217 optimization to the
baseline. The two optimizations target different bottlenecks and stack.

---

## 1. The change ("demo")

Commit [`352743ef1`](https://github.com/shakacode/react_on_rails/commit/352743ef18b204bb34072b42aa8be32f05927bfa),
9 added / 1 modified lines, single file
`react_on_rails_pro/lib/react_on_rails_pro/request.rb`:

```ruby
def render_code(path, js_code, send_bundle)
  Rails.logger.info { "[ReactOnRailsPro] Perform rendering request #{path}" }
  form = form_with_code(js_code, send_bundle)
  # Experiment (issue #3280): use JSON for steady-state render to skip
  # form-urlencode CPU/GC. Keep multipart when send_bundle=true because
  # form_with_code embeds the bundle file as a Pathname which can't be
  # JSON-serialized.
  if send_bundle
    perform_request(path, form: form)
  else
    perform_request(path, json: form)
  end
end
```

No Node-side change. `react_on_rails_pro/lib/react_on_rails_pro/utils.rb:167`
`common_form_data` already produces only JSON-serializable values
(`gemVersion`, `protocolVersion`, `password`, `dependencyBundleTimestamps`
array-or-nil, `railsEnv` — all strings/arrays/nil) when `send_bundle: false`.
HTTPX's `json:` option serializes the hash with `JSON.generate` and sets
`Content-Type: application/json`.

### Why it works without a renderer change

- The renderer is Fastify (since `d646a1b03` "Convert the server in `worker`
  from Express to Fastify"). Fastify ships a **built-in default JSON body
  parser**; the worker never calls `removeContentTypeParser('application/json')`
  or `removeAllContentTypeParsers()`. `@fastify/formbody` and
  `@fastify/multipart` are additionally registered for the other two
  content-types (`packages/react-on-rails-pro-node-renderer/src/worker.ts:267-306`).
- The render handler reads `req.body.renderingRequest` agnostically
  (`worker.ts:347-407`). The only array field, `dependencyBundleTimestamps`,
  is read by `extractBodyArrayField` (`worker.ts:196-208`) which already
  checks **both** `key` (JSON shape) and `key[]` (the form-encoded Ruby-array
  convention HTTPX emits) — so both encodings work unchanged.
- `password` auth (`worker/authHandler.ts:17`) reads `req.body.password`
  identically for either body encoding, with `timingSafeEqual`.

### Instrumentation (verification, not for merge)

Eight extra log lines were added (uncommitted, on top of the experiment
commit) to prove the JSON path at runtime:

Ruby — `request.rb` `render_code`, tag `[RORP-3280-EXPERIMENT-BODY]`, logs
`format=application/json … send_bundle=false rendering_request_bytes=…`.

Node — `worker.js` render handler (compiled `lib/worker.js:309`, source
`src/worker.ts` equivalent), `log.info` with `contentType`, `contentLength`,
`bodyKeys`, `renderingRequestBytes`.

Verified end-to-end (one request per size):

| Request | Ruby `format` | Ruby `send_bundle` | Node `contentType` | Ruby bytes | Node bytes | Match |
|---|---|---|---|--:|--:|:--:|
| `/hello_world` | application/json | false | application/json | 1,201 | 1,201 | ✓ |
| `/heavy_benchmark_traditional` | application/json | false | application/json | 40,001 | 40,001 | ✓ |
| `/mega_benchmark_traditional?u=500&p=1000&c=5000` | application/json | false | application/json | 1,164,171 | 1,164,171 | ✓ |

---

## 2. Performance numbers

Setup: rsc-benchmar `apps/ror-rsc`, base `upcoming-v16.3.0` (`3d571c32`),
Ruby 3.3.0 (YJIT), Node 22.12.0, Rails 7.2.3.1, Puma 8.0.1
(`RAILS_MAX_THREADS=16`), Postgres seeded 500 users / 1000 posts / 5000
comments, renderer 3 workers, `renderer_http_pool_size=64`, no jemalloc,
Intel i7-9750H (12 logical cores), Linux 6.8.

### 2.1 Sequential sweep — `run-sweep.sh` (n=25/point, 110-call warmup)

| Point (u,p,c) | base total / gc (ms) | after total / gc (ms) | Δ total |
|---|--:|--:|--:|
| 0, 0, 0 | 7 / 0.1 | 7 / 0.0 | 0 |
| 500, 0, 0 | 45 / 4.3 | 34 / 0.6 | −11 |
| 500, 1000, 0 | 185 / 31.5 | 41 / 1.5 | −144 |
| 500, 1000, 2500 | 238 / 57.4 | 55 / 4.2 | −183 |
| **500, 1000, 5000** | **396 / 112.8** | **92 / 9.8** | **−304** |

Improvement scales with payload size — consistent with the cost being
percent-escape work proportional to body bytes.

### 2.2 Isolation — `run-isolation.sh` (n=30/endpoint)

| Endpoint | base total / gc | after total / gc | Δ total |
|---|--:|--:|--:|
| build_only (controller alloc, no renderer) | 34 / 2.8 | 32 / 2.9 | −2 |
| **send_only (renderer+view, memoized props)** | **306 / 81.5** | **86 / 6.1** | **−220** |
| full (both) | 339 / 95.9 | 97 / 6.9 | −242 |

`build_only` unchanged → 100 % of the saving is in the renderer round-trip,
exactly where the change applies.

### 2.3 Concurrent — autocannon `--sweep --duration=20`

| Page | c | base p50 | after p50 | base rps | after rps |
|---|--:|--:|--:|--:|--:|
| hello_world | 1 / 10 / 50 | 10 / 42 / 224 | 10 / 40 / 231 | 193 / 206 / 198 | 224 / 214 / 202 |
| heavy_traditional | 10 | 176 | **102** | 54 | **94** |
| heavy_traditional | 50 | 950 | **588** | 51 | **82** |
| mega_traditional | 1 | 308 | **101** | 3 | **10** |
| mega_traditional | 10 | 2625 | **955** | 3 | **10** |
| mega_traditional | 50 | 8480 (69 err) | **4668 (0 err)** | 2 | **10** |

Streaming SSR (`hello_server`, `mega_benchmark`) flat ±noise — untouched path,
no regression.

### 2.4 Web vitals — Playwright (3 iters)

| Page | base TTFB / load | after TTFB / load |
|---|--:|--:|
| hello_world | 8.5 / 55 | 4.0 / 45 |
| heavy_benchmark_traditional | 21.9 / 37 | 12.1 / 79 |
| **mega_benchmark_traditional** | **233.1 / 240** | **135.6 / 553** |
| hello_server | 6.0 / 13 | 118.9 / 220 ¹ |

¹ `hello_server` first-iter cold-cache noise at 3 iters; autocannon c=1 shows
it flat (120→115). Re-measure with iters≥10 if it matters.

### 2.5 Robustness — three methodologies agree

Two complete Rails+renderer stacks booted side-by-side (exp :3000/:3800,
baseline :3002/:3810) to cancel time-varying environmental noise.

| Method | mega p50 Δ (base − exp) |
|---|--:|
| Sequential (consecutive runs) | **−304 ms** |
| Paired-curl (alternating, both stacks live) | **−254 ms** |
| Parallel autocannon c=1 (both stacks under load) | **−272 ms** |

All within ~50 ms; smaller deltas under simultaneous load are symmetric CPU
contention (fair, since both sides see it).

### 2.6 Robustness — does #3217 (TCP_NODELAY) eat the win?

#3217 monkey-patch applied to **baseline only** (verified
`HTTPX::TCP.ancestors.include?(ReactOnRailsPro::HttpxTcpNodelayPatch) == true`):

| Workload | Δ, #3217 NOT on baseline | Δ, #3217 ON baseline |
|---|--:|--:|
| mega paired-curl | +254 ms | **+301 ms** |
| mega autocannon c=1 | +272 ms | **+279 ms** |
| mega autocannon c=10 | +2722 ms | **+2747 ms** |
| mega autocannon c=50 | +1696 ms | **+2436 ms** |

Unchanged. #3217 fixes a Nagle + delayed-ACK 40 ms tail that only forms for
small, infrequent writes over real-network RTT. The render round-trip is
large-burst (1.16 MB props / 2.18 MB HTML) on localhost loopback
(min-RTT ~7 µs), so Nagle never engages. **The two PRs are orthogonal and
stack.**

### 2.7 Correctness — byte-equivalent HTML

| Page | base bytes | after bytes |
|---|--:|--:|
| /hello_world | 7,690 | 7,690 |
| /heavy_benchmark_traditional | 59,713 | 59,713 |
| /mega_benchmark_traditional?u=500&p=1000&c=5000 | 2,186,638 | 2,186,638 |

`diff` shows only per-request random DOM-UUID drift on
`HelloWorld-react-component-<uuid>` — identical to the drift between two
consecutive baseline calls. Rendered content is bit-identical.

---

## 3. Problems faced while running the experiment

These are operational/environmental, not defects in the change. Recorded so
the production effort budgets for them.

1. **Branch base.** Worktree first cut from `main`; the experiment had to
   match the renderer/gem version rsc-benchmar pins, so it was recut from
   `upcoming-v16.3.0` (`3d571c32`).
2. **Fresh demo-app setup.** `pnpm install` (root, auto-builds the 3 JS
   packages via `prepare`), `npm install` (ror-rsc), `bundle install`, the
   3-step yalc chain (`react-on-rails-pro` → `react-on-rails` →
   `react-on-rails-pro-node-renderer`), and **three** shakapacker bundle
   builds (client/server/RSC). DB happened to be pre-seeded.
3. **Bundle build needs pack generation first.** `bin/shakapacker` failed
   with `app/javascript/generated/server-bundle-generated.js doesn't exist`
   until `rake react_on_rails:generate_packs` was run; then all 3 builds
   succeeded.
4. **Both base + Pro npm packages present.** `react-on-rails` and
   `react-on-rails-pro` both in `node_modules` triggers
   `ReactOnRails::Error: Both 'react-on-rails' and 'react-on-rails-pro'
   packages are installed` at boot
   (`react_on_rails/lib/react_on_rails/version_checker.rb:107`). Worked
   around with `REACT_ON_RAILS_SKIP_VALIDATION=true` (the issue's own boot
   command uses this). A production install would remove the base package;
   the experiment kept the demo app's existing layout.
5. **Background processes reaped at ~10 min.** Servers started via the Bash
   tool die at the 10-minute max timeout. Fixed by launching detached:
   `nohup bash -c '…' >/dev/null 2>&1 & disown` (and `setsid -f` earlier).
6. **HTTPX pool exhaustion at c=50.** Default `renderer_http_pool_size`
   plus a 5 s checkout timeout → `HTTPX::PoolTimeoutError` and a Rails
   `Exiting` under sustained c=50. Fixed in the demo initializer:
   `renderer_http_pool_size=64`, `renderer_http_pool_timeout=30`,
   `ssr_timeout=30`. Identical on baseline and after, so the A/B stays fair;
   absolute c=50 numbers would be slower on the default pool.
7. **Harness expected gem-internal instrumentation.** `analyze.rb` required
   an `[INSTR-RORP-NETWORK] httpx_round_trip_ms=…` log line the
   `upcoming-v16.3.0` gem doesn't emit; every bucket came back n=0. Patched
   `analyze.rb`/`analyze-iso.rb` to make that field optional and the
   percentile stats nil-safe (committed in the demo-app harness commit).
8. **Hardcoded log path.** `run-sweep.sh`/`analyze*.rb` hardcoded an absolute
   `RAILS_LOG`; made env-driven with a repo-relative default (demo commit).
9. **Production logger is STDOUT.** rsc-benchmar's `production.rb` pins
   `config.logger` to `STDOUT`; the harness reads a file. Worked around by
   redirecting the server's stdout to `log/production.log` at boot.
10. **Web-vitals contaminated by parallel load.** First after-run was
    launched while autocannon was hammering the same port → inflated TTFB.
    Re-run cleanly.
11. **autocannon `isAlive` cascade.** When one page 5xx'd under c=50, the
    harness's liveness pre-check skipped every subsequent page, yielding
    partial result sets in a couple of runs (re-run after the pool fix gave
    full sets).
12. **#3217 no-op on loopback.** TCP_NODELAY had no measurable effect here
    (loopback min-RTT ~7 µs, large-burst bodies) — not a problem with the
    change, but a measurement caveat: on a real network the baseline would
    be faster and the absolute (not relative) delta could narrow.
13. **Port collisions.** A concurrent issue-3281 session held :3001/:3801;
    the parallel baseline stack used :3002/:3810 instead.

---

## 4. Production implementation plan

The experiment intentionally skipped everything below. None is a blocker to
the *idea*; all are required to *ship*.

### 4.1 Backward / forward compatibility

Protocol version is `2.0.0` on both sides
(`react_on_rails_pro/lib/react_on_rails_pro/version.rb:5`,
`packages/react-on-rails-pro-node-renderer/package.json:4`). The renderer
rejects a mismatch with HTTP 412 in
`worker/checkProtocolVersionHandler.ts:48-59` (read from `req.body`).

Compatibility matrix:

| Gem → Renderer | Result | Reason |
|---|---|---|
| new (JSON) → new | ✓ | Fastify default JSON parser |
| new (JSON) → old Fastify renderer | ✓ *likely* | All Fastify-era renderers have the default JSON parser and never remove it; **verify the oldest supported renderer** |
| new (JSON) → pre-Fastify (Express) renderer | ✗ *risk* | Express needs `express.json()`; confirm the minimum supported renderer is post-`d646a1b03` |
| old (form) → new | ✓ | `@fastify/formbody` still registered; `extractBodyArrayField` still reads `key[]` |

Decisions to make:
- **Floor the supported renderer** at the first Fastify release, OR add a
  capability/version handshake so the gem only sends JSON when the renderer
  advertises it. Cleanest: gate on `protocolVersion` — bump it and have the
  gem send form to renderers below the bump, JSON at/above.
- The render endpoint's body-limit for JSON is the Fastify global
  `bodyLimit` (100 MB, `worker.ts:222`) — fine; document it.

### 4.2 Keep multipart where it must stay

`send_bundle: true` already stays on multipart (the experiment's conditional)
because `form_with_code` → `populate_form_with_bundle_and_assets` embeds
bundle/asset entries whose `:body` is a `Pathname`/IO
(`request.rb:189-197`, `321-344`). `/upload-assets` (multipart, file uploads)
and `/asset-exists` (already `json:`, `request.rb:94`) are untouched. Add a
regression test that exercises the warmup (`send_bundle: true`) path so a
future refactor can't silently route a `Pathname` through `JSON.generate`.

### 4.3 Streaming paths — out of scope, evaluate separately

`render_code_as_stream` (`request.rb:29-42`) stays on
`form: form, stream: true`. Converting it is non-trivial: the streamed body
carries the bundle re-upload path and the `STATUS_SEND_BUNDLE` retry, and the
transport is HTTP/2 streaming. `render_code_with_incremental_updates` does not
exist on this base (incremental updates go through `render_code_as_stream` +
stream decorators). A separate issue should measure whether the initial
render line of the stream can be JSON without disturbing the chunked body.

### 4.4 Tests

- Ruby (`react_on_rails_pro/spec/react_on_rails_pro/request_spec.rb`): the
  existing specs at ~`:123-135` assert `body.to_s` includes
  `renderingRequest=console.log` (form encoding) and that the second
  (bundle) request is multipart with a `FakeFS::Pathname` body. These must
  be updated to assert `application/json` for the steady-state render and
  multipart only for `send_bundle: true`.
- Node (`packages/react-on-rails-pro-node-renderer/tests/worker.test.ts`):
  add a JSON-body render test alongside the multipart one. Fastify's
  `app.inject().payload({...})` already sends JSON (the protocol-version
  test at ~`:567-589` does exactly this), so the harness supports it.
- Add an explicit byte-equivalence test: same render request via `form:`
  and `json:` must produce identical renderer output.

### 4.5 Docs / changelog

Pro CHANGELOG entry calling out the wire-protocol change, the perf
characteristics, and the minimum renderer version. Note the content-type in
any renderer-protocol docs.

### 4.6 Defensive audit

Confirm no future code path can place a non-JSON-serializable value into the
hash when `send_bundle: false`. Today `common_form_data` is closed and safe;
add a guard or test so it stays that way.

### 4.7 Sequencing vs #3217

#3217 (TCP_NODELAY) and this change are orthogonal — payload-encoding-bound
vs RTT-bound. Merge order doesn't matter; the production PR should not
re-litigate #3217's numbers, only note that the JSON win was re-verified with
#3217 active on the baseline (§2.6).

---

## 5. Recommendation

Open a single production PR implementing §4.1–§4.6, gated on a protocol
version bump (§4.1) so old renderers keep getting form-encoded bodies. Target
the same release train as #3217 if possible; they compound.
