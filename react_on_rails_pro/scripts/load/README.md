# Renderer Transport Load and Memory Harness

A reproducible Ruby-based load and memory harness for the React on Rails Pro Rails → Node renderer transport. Designed to compare HTTPX vs async-http transports on correctness, latency, throughput, and memory growth.

## Status

This is the **foundation** PR. It ships:

- Two runnable scenarios: `standard_render`, `streaming_render`
- Metrics (latency percentiles, RPS, memory slope), output as JSON + CSV + terminal summary
- Smoke mode for quick local + CI validation
- Harness unit tests (no live HTTP)

Deferred to follow-up issues:

- Incremental async scenario — requires a JS handler that accepts NDJSON async-prop chunks AND renders via `ReactOnRails.addAsyncPropsCapabilityToComponentProps`. That method is only available in the RSC bundle; the plain server bundle lacks it. The integration tests use special fixture bundles (`react-on-rails-pro-node-renderer/tests/fixtures/bundle-incremental.js`) with a `ReactOnRails.getStreamValues()` helper not present in production bundles. No runnable Ruby scenario ships until an RSC-capable test component or fixture is wired up.
- 410 missing-bundle retry scenario
- Stale-connection scenario (renderer restart)
- Early-disconnect / cancel scenario
- Timeout / hung-renderer scenario
- Comparison mode (diff two run dirs, pass/fail on memory slope + p99 deltas)

## Prerequisites

1. Bundled gems for the dummy app (`cd react_on_rails_pro/spec/dummy && bundle install`).
2. Built JS bundles (the dummy app build chain — see the dummy app README and `react_on_rails_pro/CLAUDE.md`).
3. The node renderer running. From `react_on_rails_pro/spec/dummy/`: `pnpm run node-renderer` (default port 3800).
4. A running Rails app is **not** required to run the harness — the harness uses `bin/rails runner`, which boots Rails in-process to use the existing initializer config.

## Running

All commands run from `react_on_rails_pro/spec/dummy/`:

### Smoke (fastest sanity check, ~30s wall clock)

```bash
bin/renderer-harness --smoke
```

Runs 10 standard-render requests, concurrency 1, no warmup. Exits 0 on success.

### Standard scenarios

```bash
# Non-streaming render, 1000 requests across 4 threads
bin/renderer-harness --scenario standard_render --requests 1000 --concurrency 4 --warmup 5

# Streaming render, 60s with 4 threads
bin/renderer-harness --scenario streaming_render --duration 60 --concurrency 4
```

`--warmup` is per worker thread. For example, `--warmup 5 --concurrency 4` issues 20 warmup
requests before measured requests begin. All workers must finish warmup before measurement starts;
`--start-gate-timeout` controls how long to wait for them (default: 30 seconds).

### Tracking the node-renderer process

To include the node-renderer RSS in `memory.csv`, pass its PID:

```bash
RENDERER_PID=$(pgrep -f "node-renderer")
bin/renderer-harness --scenario standard_render --requests 1000 --renderer-pid $RENDERER_PID
```

## Output

Each run writes to `tmp/load-tests/<UTC-timestamp>/` (gitignored):

- `summary.json` — config, env, aggregates, memory slope
- `latency.csv` — per-request samples
- `memory.csv` — time-series of RSS + GC.stat

A summary block prints to the terminal at the end.

## Interpreting Results

- **p99 latency**: tail latency. Sensitive to GC pauses, connection-pool contention, transport bugs.
- **Failure rate**: anything above 0% during steady-state warrants investigation.
- **Memory slope**: linear regression of RSS post-warmup, in MB/min. A small positive slope is expected as caches warm; a sustained slope > a few MB/min over a long run is a leak suspicion.
- **GC.stat live_slots**: grows quickly then plateaus normally. Continued growth is a leak signal.

## Transport selection

The harness reads `REACT_ON_RAILS_RENDERER_TRANSPORT` (default `httpx`) and records it in `summary.json`. This PR does not switch transports — the async-http branch will add an `async_http` value when it merges. To compare:

```bash
# baseline
REACT_ON_RAILS_RENDERER_TRANSPORT=httpx bin/renderer-harness --scenario streaming_render --duration 60

# (after async-http branch is checked out)
REACT_ON_RAILS_RENDERER_TRANSPORT=async_http bin/renderer-harness --scenario streaming_render --duration 60
```

## Caveats

- `ps -o rss=` units are kB on both macOS and Linux but reporting is best-effort; if the process is gone mid-sample, the row is omitted (not zero-filled).
- FD count is not yet collected — planned for follow-up.
- The harness uses the renderer URL and password from the dummy app initializer (`config/initializers/react_on_rails_pro.rb`).

## CI

- Harness unit tests run with the regular Pro gem unit test sweep (`cd react_on_rails_pro && bundle exec rspec spec/load/`).
- Live smoke is opt-in via `RUN_RENDERER_LOAD_SMOKE=1`; it is not wired into any default workflow in this PR.
