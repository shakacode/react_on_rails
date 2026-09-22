# PPR ShakaPerf Benchmark Gate

This ShakaPerf gate measures the Partial Prerendering headline claim (plan of record §6):
**PPR warm-hit TTFB ≤ 10% of the same route's streaming-SSR TTFB, with LCP no worse** — issue
#5103. It runs `--categories perf` (the repo's first live use of the perf category) against the
React on Rails Pro dummy app.

## Checks

- `ppr warm hit serves cached shell and streams hole content`: both sides load
  `/ppr_page_for_testing`. Every measured sample asserts the shell arrived inside the 400ms
  warm-hit budget (a cold prerender cannot flush before the 500ms settle timer) and that the
  streamed hole content actually rendered. Absolute assertions — fails even when both sides
  are the same broken build.
- `ppr warm hit vs streaming ssr ttfb and lcp`: the A/B pair. Control =
  `/stream_async_components_for_testing` (streaming SSR), experiment = `/ppr_page_for_testing`
  (PPR warm hit), same server. The verdict comes from the report's TTFB/LCP statistics rows.

Both tests warm their route with a drained GET before **every** measured navigation
(`beforeNavigate`), so every Lighthouse sample — including the harness's `perf-warmup`
stage — measures a warm hit.

## Provisional until #5101

The control route renders a structurally similar but different component tree (streamed ~1s
async holes). Until #5101 lands the same component in plain-SSR/streaming/PPR modes, this pair
compares delivery mode _plus_ content. Override without code changes:

```bash
SHAKAPERF_PPR_PATH=/new_ppr_route SHAKAPERF_STREAMING_SSR_PATH=/new_streaming_route ...
```

The PPR-vs-plain-SSR secondary pair is absent until #5101 resolves the "plain SSR cannot await
the async hole" wrinkle. The warm-hit proof is behavioral (TTFB bound); wiring the
`ppr.cache.lookup` events (#5102) into an externally checkable assertion is the planned upgrade.

## Local Run

Start the Pro dummy app with test assets, the node renderer, and — critical — the PPR cache
enabled (`RAILS_ENV=test` otherwise uses `:null_store` and every request is a cold miss).
`WEB_CONCURRENCY=0` (single-mode Puma) is equally critical: the gate's `:memory_store` is
per-process, so clustered workers each have their own empty cache and measured requests land
on cold workers at random:

```bash
cd react_on_rails_pro/spec/dummy
RENDERER_PORT=3800 pnpm run node-renderer &
WEB_CONCURRENCY=0 SHAKAPERF_PPR_CACHE=true RAILS_ENV=test NODE_ENV=test PORT=3000 \
  REACT_RENDERER_URL=http://127.0.0.1:3800 \
  bundle exec rails s -b 127.0.0.1 -p 3000 &
```

Then, from the repo root:

```bash
pnpm exec shaka-perf compare \
  --categories perf \
  --config test/shakaperf/ppr/abtests.config.ts \
  --filter test/shakaperf/ppr/ab-tests/ppr-release-gate.abtest.ts \
  --controlURL http://127.0.0.1:3000 \
  --experimentURL http://127.0.0.1:3000 \
  --full-report-zip
```

Reports are written to `compare-results/`. `SHAKAPERF_PPR_MEASUREMENTS` overrides the sample
count (default 12; the Wilcoxon test cannot reach p < 0.05 below 6 clean pairs, so never go
lower — the final value is tuned from observed variance on the M1 runner per #5103).

Two environment gotchas:

- shaka-perf's `--categories perf` needs Node ≥ 20.6 (`module.register()` for the Lighthouse
  patch), and its bin shim re-execs the Node binary **pinned at install time**
  (`node_modules/shaka-perf/bin/.node-path`). If `pnpm install` ran under an older Node, either
  reinstall under the right one or override per run: `SHAKA_PERF_NODE=$(which node)`.
- `annotate()` labels are limited to 50 characters; longer labels fail the test at runtime.
