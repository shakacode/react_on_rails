# Design: Renderer Transport Load and Memory Harness

- **Issue:** [#3278](https://github.com/shakacode/react_on_rails/issues/3278)
- **Branch:** `jg-conductor/3278-fix`
- **Status:** Approved (2026-05-23)
- **Scope:** Foundation PR (option B). Lands core harness + three scenarios + smoke mode + harness tests + docs. Defers four scenarios and comparison mode to follow-up issues.

## Goal

Provide a reproducible Ruby-based load and memory harness that exercises the real `ReactOnRailsPro::Request` transport against the dummy node renderer, so HTTPX vs async-http can be compared on latency, throughput, and memory growth.

This PR establishes the foundation. It does **not** add the four advanced scenarios (410 retry, stale connection, early disconnect, timeout) or comparison mode — those become follow-up issues.

## Non-Goals

- No production transport changes other than reading one new env var name into the run summary.
- No mocked HTTP. The harness exercises the actual transport stack against a live node renderer.
- No CI-blocking load runs. Internal harness unit tests run in CI; live smoke is opt-in via env var.
- No Rust rewrite, no replacing the test-app setup.

## Architecture

### Approach

Standalone Ruby CLI at `react_on_rails_pro/scripts/load/renderer_harness.rb` that loads the Pro gem, configures `ReactOnRailsPro::Request`, and drives scenarios against a user-started dummy app + node renderer.

Alternatives considered:

- **Rake task in dummy app** — rejected: couples harness to dummy lifecycle and makes flag passing awkward.
- **RSpec-based** — rejected: RSpec overhead distorts measurements; semantics don't fit sustained load.

### Directory layout

```
react_on_rails_pro/
  scripts/load/
    README.md
    renderer_harness.rb               # CLI entry
    lib/
      harness.rb                      # orchestrator (warmup -> run -> drain -> report)
      runner.rb                       # thread-pool concurrency, request loop
      metrics.rb                      # percentile + RPS + slope computation
      memory_sampler.rb               # background sampler thread (RSS, GC.stat, FD count)
      reporters/
        json_reporter.rb
        csv_reporter.rb
        terminal_reporter.rb
      scenarios/
        base.rb                       # interface: warmup / perform_request / cleanup
        standard_render.rb
        streaming_render.rb
        incremental_async.rb
  spec/load/
    metrics_spec.rb
    reporters_spec.rb
    memory_sampler_spec.rb
```

`tmp/` is already gitignored at the repo root; outputs at `tmp/load-tests/<UTC-timestamp>/` are not committed.

### CLI shape

```
ruby react_on_rails_pro/scripts/load/renderer_harness.rb --help

  --scenario NAME           standard_render | streaming_render | incremental_async
  --requests N              total requests across all threads (mutually exclusive with --duration)
  --duration SECONDS        wall-clock run length (mutually exclusive with --requests)
  --concurrency N           number of worker threads (default 1)
  --warmup N                warmup requests per thread, excluded from stats (default 5)
  --mix small|medium|large  payload size preset (see "Mix sizes" below) (default small)
  --increments N            incremental_async only: emit N synthetic prop updates per request (default 5)
  --mem-interval SECONDS    memory sampling interval (default 1)
  --renderer-pid PID        node-renderer PID for RSS sampling (optional)
  --output-dir PATH         override output dir (default tmp/load-tests/<UTC-timestamp>)
  --smoke                   preset: 10 requests, concurrency 1, no warmup, standard_render
  --help
```

Exclusivity: exactly one of `--requests` or `--duration` is required (unless `--smoke`).

### Mix sizes

`--mix` controls component props payload size in the request body. Concrete sizes:

| Mix      | Props JSON size | Use                                   |
| -------- | --------------- | ------------------------------------- |
| `small`  | ~200 bytes      | Default. Latency/throughput baseline. |
| `medium` | ~10 KB          | Realistic page payload.               |
| `large`  | ~100 KB         | Stress serialization + transport.     |

### Config / auth

The harness loads `react_on_rails_pro/spec/dummy/config/initializers/react_on_rails_pro.rb` to pick up renderer URL, JWT password, and any other transport settings — same config the dummy app uses. No new credentials needed if the dummy is already runnable locally.

### Scenarios

Each scenario implements:

```ruby
class Scenarios::Base
  def initialize(config); end
  def warmup(n); end
  def perform_request; end   # returns RequestResult
  def cleanup; end
end

RequestResult = Struct.new(
  :latency_ms, :bytes_in, :bytes_out, :ok, :error, :http_status, :scenario,
  keyword_init: true
)
```

| Scenario            | Transport path                                           | What it measures                                                                                                                                                 |
| ------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `standard_render`   | `Request.render_code` against `/render`                  | One-shot POST, baseline throughput                                                                                                                               |
| `streaming_render`  | `Request.render_code_as_stream` against `/render_stream` | Streaming POST + chunked drain; fully consumes response                                                                                                          |
| `incremental_async` | `Request.render_code_with_incremental_updates`           | Bidirectional HTTP/2 stream; async-props block emits N synthetic updates then closes (END_STREAM). Most likely place to surface HTTPX vs async-http differences. |

Failure modes recorded as `RequestResult` with `ok: false` and an error message rather than aborting the run.

### Concurrency model

N Ruby threads share a single `ReactOnRailsPro::Request` connection (matches production). Configurable concurrency: 1 / 4 / 16 typical; arbitrary integers allowed.

Work distribution:

- `--requests N`: threads pull from a shared atomic counter (`Concurrent::AtomicFixnum` or `Mutex`-guarded `Integer`) so they collectively make exactly N requests regardless of per-thread timing variance.
- `--duration S`: each thread loops until the wall-clock deadline.

Warmup runs per-thread (each thread issues `--warmup` requests before the shared counter / timer starts), so transport-level state (TCP connections, HTTP/2 streams) is established in every worker before measurement begins.

### Metrics

**Per-request samples** (flushed to `latency.csv` at end):

`t_started_ms, latency_ms, bytes_in, bytes_out, ok, error, http_status, scenario, thread_id`

**Aggregated summary** (in `summary.json` and terminal output):

- `count`, `failures`, `failure_rate`, `rps`
- Latency percentiles: `p50, p90, p95, p99, p99_9, max, mean`
- Per-scenario breakdown

**Memory sampler** runs as a separate thread sampling every `--mem-interval` seconds:

- Rails process RSS via `ps -o rss= -p <pid>` (portable across macOS + Linux)
- Node renderer RSS via same `ps` call when `--renderer-pid` provided
- `GC.stat` snapshot: `heap_live_slots, total_allocated_objects, malloc_increase_bytes, oldmalloc_increase_bytes`
- Open FD count: `Dir.glob("/proc/#{pid}/fd/*").size` on Linux, `lsof -p <pid> | wc -l` fallback on macOS. Marked best-effort and omitted (not faked) if unavailable.

**Memory slope** = linear regression of RSS samples after the warmup window, expressed as MB/min. This is the primary leak signal.

### Output

`tmp/load-tests/<UTC-timestamp>/`:

- `summary.json` — config, env (ruby version, transport name, hostname), aggregates, per-scenario breakdown, slope
- `latency.csv` — per-request samples
- `memory.csv` — time-series of all sampled processes + GC.stat
- `run.log` — human-readable progress + warnings (e.g. "FD count unavailable on macOS")

Terminal summary printed at end (example in §"Acceptance criteria").

### Smoke mode

`--smoke` = 10 requests, concurrency 1, no warmup, scenario `standard_render`. Wall clock < ~30s once node-renderer is up. Asserts:

- exit 0
- all three output files exist and parse
- zero failures
- p99 latency under 5s sanity ceiling

Intended for local validation and as an opt-in CI gate behind `RUN_RENDERER_LOAD_SMOKE=1`.

## Production code changes

Tiny, opt-in only:

1. Add a constant for the env var name `REACT_ON_RAILS_RENDERER_TRANSPORT` (default `"httpx"`). Read into `summary.json` for the run record. **No behavior switching in this PR.** The async-http branch will add an `async_http` value when it merges.

Anything else (e.g. exposing connection stats) is deferred — if HTTPX doesn't expose pool counts cleanly, skip it rather than monkey-patch.

## Tests

Harness unit tests live at `react_on_rails_pro/spec/load/` (sibling to `spec/react_on_rails_pro/`). They have a tiny dedicated `spec_helper.rb` that requires the harness lib files directly — no Rails / dummy app boot, no live HTTP, no node-renderer launch. Fast.

Specs:

- `metrics_spec.rb` — percentile correctness (known fixtures including empty, single sample, identical samples), RPS from elapsed + count, slope on a known time series
- `reporters_spec.rb` — JSON shape, CSV header + row count, terminal formatting
- `memory_sampler_spec.rb` — parses `ps` output stub, handles missing PID, slope from synthetic series

Both `bundle exec rspec spec/load/` and `bundle exec rspec spec/` (which picks up everything) must work.

## CI

- Harness unit tests run with regular Pro gem tests (no extra workflow file needed)
- Smoke mode is opt-in behind `RUN_RENDERER_LOAD_SMOKE=1` env var; **not wired into any default workflow** in this PR
- README documents the smoke command for future CI integration

## Documentation

`react_on_rails_pro/scripts/load/README.md` covers:

- Prereqs (Ruby + bundled gems, dummy app deps + bundle built)
- Setup commands (start node-renderer, start Rails — link to dummy README for details rather than duplicate)
- Run examples: smoke / standard / streaming / incremental
- Interpretation: p99, failure rate, memory slope (what's a leak vs growth-to-steady-state)
- Caveats: FD count best-effort, macOS vs Linux RSS unit differences
- **Planned scenarios** section listing the four deferred (410 retry, stale connection, early disconnect, timeout) with one-line reason each
- **Planned comparison mode** placeholder linking to the follow-up issue

## Acceptance criteria

1. `ruby react_on_rails_pro/scripts/load/renderer_harness.rb --smoke` exits 0 against the dummy app + node renderer.
2. `cd react_on_rails_pro && bundle exec rspec spec/load/` passes.
3. Each of the three scenarios produces non-empty `summary.json` + `latency.csv` + `memory.csv` for a meaningful run (`--requests 100 --concurrency 4`).
4. README documents prereqs, every flag, interpretation, and the deferred items.
5. Existing Pro tests still pass; no production behavior change other than reading the new env-var name.
6. PR description includes exact commands run and abbreviated sample output.

Example terminal summary (illustrative, real numbers will vary):

```
=== Renderer Load Harness Results ===
Scenario: streaming_render | Concurrency: 4 | Duration: 60s
Transport: httpx (REACT_ON_RAILS_RENDERER_TRANSPORT=httpx)

Requests: 12,431 (failures: 3, 0.02%)
RPS: 207.2

Latency (ms):  p50=14  p90=22  p95=31  p99=78  p99.9=145  max=812
Rails RSS:     start=142MB  end=158MB  slope=+0.4MB/min  (over 55s post-warmup)
Renderer RSS:  start=410MB  end=419MB  slope=+0.2MB/min
GC.live_slots: start=412k   end=438k

Output written to: tmp/load-tests/2026-05-21T18-04-22Z/
```

## Follow-up issues to file after this PR lands

1. 410 missing-bundle retry scenario (`upload_assets` -> retry -> success).
2. Stale-connection scenario (renderer restart between requests).
3. Early-disconnect / cancel scenario (stop consuming after first chunk).
4. Timeout / hung-renderer scenario.
5. Comparison mode: diff two run dirs, pass/fail summary on memory slope + p99 deltas, transport switch (`REACT_ON_RAILS_RENDERER_TRANSPORT=async_http`).
