# Memory Leak Reproducer

Measures RSS growth per SSR request in the react_on_rails_pro Node Renderer pipeline.
This is a measurement tool, not a fix. It produces a `kb_per_req` metric that subsequent
demo-experiment issues use as their baseline.

## Requirements

- **Linux** with `/proc` filesystem (uses `/proc/<pid>/status` for VmRSS sampling)
- `curl` installed
- Precompiled production assets (see Quick Start)

## Quick Start

From a fresh clone:

```bash
cd react_on_rails_pro/spec/dummy

# Install dependencies (the dummy app's preinstall script handles yalc linkage)
pnpm install

# Precompile production assets
RAILS_ENV=production bin/prod-assets

# Run the reproducer
script/leak_repro
```

## What the Script Does

1. Boots the **node renderer** in the background (3 workers, 5-minute restart interval)
2. Boots **puma** in production mode with `WEB_CONCURRENCY=1`, `RAILS_MAX_THREADS=3`,
   all caching disabled (`LEAK_REPRO=1`)
3. Locates the puma worker PID (the single cluster-worker child)
4. Sends 2,000 requests to `/leak_repro` at concurrency 3
5. Samples `VmRSS` from `/proc/<pid>/status` every 10 requests, writing rows to
   `tmp/leak_repro_metrics.csv`
6. Reports `kb_per_req` for the post-warmup measurement window (requests 501-2000)
7. Tears down both servers on exit

The `/leak_repro` endpoint uses `react_component_hash` to server-render a component
that produces >= 80 KB of HTML (200 items with inline styles), exercising the full
SSR pipeline: HTTPX connection, bundle upload/410 retry, ChunkExtractor, HelmetProvider,
and `renderToString`.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LEAK_REPRO_REQUESTS` | `2000` | Total number of requests |
| `LEAK_REPRO_CONCURRENCY` | `3` | Parallel request count |
| `LEAK_REPRO_WARMUP` | `500` | Requests to discard before measurement |
| `LEAK_REPRO_ITEM_COUNT` | `200` | Items rendered per page (controls HTML size) |
| `LEAK_REPRO_SAMPLE_INTERVAL` | `10` | Sample RSS every N requests |
| `PORT` | `3001` | Puma listen port |
| `RENDERER_PORT` | `3800` | Node renderer listen port |

## Output

### CSV: `tmp/leak_repro_metrics.csv`

```
n,ts_ms,rss_kb,delta_kb,kb_per_req
0,1716000000000,120000,0,0.00
10,1716000000100,120500,500,50.00
...
```

### Summary (printed to stdout)

```
================================================================
  Memory Leak Reproducer Results
================================================================
  Baseline RSS:             120000 KB
  RSS after warmup (500 req): 145000 KB
  Final RSS (2000 req):       220000 KB

  Post-warmup growth:       75000 KB over 1500 requests
  Post-warmup kb_per_req:   50.00
================================================================
  PRIMARY TARGET MET: kb_per_req >= 50
```

## Baseline (dev machine, 2026-05-13)

Initial runs on a Linux dev machine (Ruby 3.3.7, Puma 6.5.0, 2000 requests, concurrency 3).

| Metric | Run 1 | Run 2 | Run 3 | Notes |
|--------|-------|-------|-------|-------|
| Baseline RSS (KB) | 147,236 | 146,956 | 150,264 | Before any requests |
| RSS after warmup (KB) | 183,920 | 187,680 | 193,484 | After 500 requests |
| Final RSS (KB) | 193,836 | 192,888 | 211,836 | After 2000 requests |
| Post-warmup growth (KB) | 9,916 | 5,208 | 18,352 | Final - warmup RSS |
| Post-warmup `kb_per_req` | 6.61 | 3.47 | 12.23 | Growth / 1500 requests |
| Overall `kb_per_req` | 23.30 | 22.97 | 30.79 | Includes warmup |

**Summary:** Post-warmup mean ~7.4 kb_per_req with high variance (~90%).
Band: **inconclusive** (variance > 10% across runs) / **refuted** (< 15 kb_per_req).

Most RSS growth occurs during warmup (JIT, code loading, initial allocations).
Post-warmup growth is relatively flat, suggesting the leak may need longer runs,
higher concurrency, or production-like conditions to manifest.

## Verification Rubric

Subsequent demo-experiment PRs must report one of these bands:

| Band | Condition | Meaning |
|------|-----------|---------|
| **confirmed** | `kb_per_req >= 50` | Leak reproduces at primary target level |
| **reduced** | `15 <= kb_per_req < 50` | Partial improvement, needs further investigation |
| **refuted** | `kb_per_req < 15` | Leak effectively eliminated by the change |
| **inconclusive** | Variance > 10% across 3 runs | Measurement too noisy; investigate system load |

## What Caching is Disabled (and Why)

When `LEAK_REPRO=1`:

- `Rails.application.config.cache_store = :null_store` — prevents fragment caching
- `config.action_controller.perform_caching = false` — disables controller caching
- `ReactOnRailsPro.configuration.prerender_caching = false` — forces every request
  through the full SSR render (no cached HTML reuse)

This ensures every request exercises the full allocation-heavy path: props serialization,
HTTPX transport, bundle evaluation, `renderToString`, and response parsing.

## Troubleshooting

**Assets not precompiled:**
Run `RAILS_ENV=production bin/prod-assets` from the dummy app directory.

**Port already in use:**
Set `PORT` and/or `RENDERER_PORT` to available ports.

**macOS / no /proc:**
This script requires Linux. On macOS, you could substitute `ps -o rss= -p $PID`
for the RSS sampling, but the script does not do this automatically.

**Puma worker PID not found:**
The script retries for 10 seconds. If it still fails, check that `WEB_CONCURRENCY=1`
is set (clustered mode required — the script tracks the forked worker, not the master).

**License errors on boot:**
Set `REACT_ON_RAILS_PRO_LICENSE` to a valid license key.
