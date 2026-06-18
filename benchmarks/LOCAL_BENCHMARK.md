# Local dedicated-hardware benchmarking

Shared GitHub-hosted runners can't produce a trustworthy microbenchmark signal: CPU
contention from noisy neighbors causes ±50–125% bidirectional swings, which fired five
false-positive regression issues in one evening (#4038–#4044, see #4071). The fix is a
**dedicated, always-on machine** that does nothing else, so its numbers are stable enough to
track a release-candidate trend.

[`run-local-benchmark.rb`](run-local-benchmark.rb) runs a benchmark suite on such a machine
and uploads to its own Bencher testbed. Tracking issue: **#4073**.

## Why a local script (not a self-hosted runner)

This is a **public** repository. A self-hosted GitHub Actions runner on a public repo is a
standing security liability: a fork pull request (or any workflow that targets the runner's
label on a fork-accessible event) can run arbitrary code on your hardware, and the runner is
persistent — one bad job can install persistence, read local secrets, or pivot to your LAN.

The local script avoids that **by construction, not by configuration**:

- GitHub never initiates execution on your machine. There is no runner to register, no
  listener, no webhook, and no label to misconfigure — so there is **zero fork-PR surface**.
- It only ever runs the code you already checked out (`git fetch origin main`), the same
  trust level as running the test suite locally.
- The Bencher token lives only on your machine, used by this script.

The only thing given up vs a runner is the GitHub Actions UI trigger — replaced by a local
schedule you control (below).

## Prerequisites

On the dedicated machine:

- Ruby (per [`.tool-versions`](../.tool-versions)), Node, `pnpm`, and
  [`k6`](https://grafana.com/docs/k6/latest/set-up/install-k6/).
- The [`bencher`](https://bencher.dev/docs/explanation/bencher-run/) CLI on `PATH`.
- `BENCHER_API_TOKEN` exported (for uploads). For the `pro` suite, also
  `REACT_ON_RAILS_PRO_LICENSE`.
- Create the `m1-bench` testbed in the
  [`react-on-rails-t8a9ncxo`](https://bencher.dev/perf/react-on-rails-t8a9ncxo) Bencher
  project (or let the first upload create it). Its baseline is independent from the shared
  `github-actions` testbed — dedicated-hardware numbers are not comparable to shared-runner
  history, so they start a fresh series.

## Usage

```bash
# Full run of the core suite, upload to the m1-bench testbed:
BENCHER_API_TOKEN=… ruby benchmarks/run-local-benchmark.rb core

# Validate locally without touching Bencher:
ruby benchmarks/run-local-benchmark.rb core --no-upload

# Pro suite, fail (exit 1) if a regression is flagged — useful as a release-candidate gate:
BENCHER_API_TOKEN=… REACT_ON_RAILS_PRO_LICENSE=… \
  ruby benchmarks/run-local-benchmark.rb pro --fail-on-alert

# Re-run against an already-built app (skip the build/setup steps):
ruby benchmarks/run-local-benchmark.rb core --no-setup --no-upload
```

Options: `--testbed NAME` (default `m1-bench`), `--[no-]upload`, `--fail-on-alert`,
`--[no-]setup`, `--duration`, `--rate`, `--connections`. See `--help`.

The script reuses the CI building blocks (no duplicated benchmark logic): per-suite config
from `generate_matrix.rb`, the dummy app's `bin/prod*` for the build + server, `bench.rb` for
the measurement, and `lib/bencher_runner.rb` for the upload (same tuned thresholds, with the
testbed overridden via `BENCHER_TESTBED`). It always reports to the testbed's `main` series —
this machine benchmarks merged `main`, so its history is one clean dedicated-hardware trend.

**Supported suites:** `core`, `pro` (rails + k6). The `pro-node-renderer` suite needs extra
steps (renderer cache pre-seed, a separate server + vegeta target) and is deferred — run it
in CI for now.

## Scheduling (nightly trend + RC)

For a nightly trend, drive it from `launchd` (or `cron`) on the dedicated machine — still no
GitHub-triggered execution. Example `~/Library/LaunchAgents/com.shakacode.ror-benchmark.plist`
running core nightly at 03:00:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key><string>com.shakacode.ror-benchmark</string>
    <key>StartCalendarInterval</key>
    <dict><key>Hour</key><integer>3</integer><key>Minute</key><integer>0</integer></dict>
    <key>WorkingDirectory</key><string>/path/to/react_on_rails</string>
    <key>EnvironmentVariables</key>
    <dict><key>BENCHER_API_TOKEN</key><string>…</string></dict>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string><string>-lc</string>
      <string>git fetch origin main &amp;&amp; git checkout origin/main &amp;&amp; ruby benchmarks/run-local-benchmark.rb core</string>
    </array>
    <key>StandardOutPath</key><string>/tmp/ror-benchmark.log</string>
    <key>StandardErrorPath</key><string>/tmp/ror-benchmark.err</string>
  </dict>
</plist>
```

Load it with `launchctl load ~/Library/LaunchAgents/com.shakacode.ror-benchmark.plist`. At
release-candidate time, run it by hand (optionally `--fail-on-alert`) against the RC ref.
