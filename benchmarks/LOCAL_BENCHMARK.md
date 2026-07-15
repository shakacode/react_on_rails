# Local dedicated-hardware benchmarking

Shared GitHub-hosted runners can't produce a trustworthy microbenchmark signal: CPU
contention from noisy neighbors causes ±50–125% bidirectional swings, which fired five
false-positive regression issues in one evening (#4038–#4044, see #4071). The fix is a
**dedicated, always-on machine** that does nothing else, so its numbers are stable enough to
track a release-candidate trend.

[`run-local-benchmark.rb`](run-local-benchmark.rb) runs a benchmark suite on such a machine
and uploads to its own Bencher testbed. Tracking issue: **#4073**.

## Operator quickstart: main vs RC

Use this flow when a release candidate needs a credible local comparison against current
`main`. Run it first without upload, inspect the local artifacts, then repeat with upload
only if the machine stayed quiet and the result is worth publishing.

```bash
git fetch --tags origin main

ruby benchmarks/run-local-benchmark-comparison.rb core \
  --a-ref v17.0.0.rc.5 --a-name rc5 \
  --b-ref origin/main --b-name main \
  --baseline rc5 --candidate main \
  --repetitions 5 \
  --duration 30s \
  --connections 10 \
  --no-upload
```

After the run, inspect:

- `bench_results/local_comparison/<timestamp>/comparison_summary.md`
- `bench_results/local_comparison/<timestamp>/comparison_summary.json`
- each run's `quiet_samples.json`

If the machine was used during the run, or the quiet samples show contamination, discard the
artifact directory and rerun. If the summary is credible and should become part of the
dedicated Bencher trend, repeat the same command with `--upload` and the local Bencher
credentials loaded:

```bash
BENCHER_API_KEY=... ruby benchmarks/run-local-benchmark-comparison.rb core \
  --a-ref v17.0.0.rc.5 --a-name rc5 \
  --b-ref origin/main --b-name main \
  --baseline rc5 --candidate main \
  --repetitions 5 \
  --duration 30s \
  --connections 10 \
  --upload
```

If the machine keeps credentials in a local shell file, source that file before running the
command. Do not commit or print local credential files. For Pro suites, load
`REACT_ON_RAILS_PRO_LICENSE` as well.

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

- Node, `pnpm`, and [`k6`](https://grafana.com/docs/k6/latest/set-up/install-k6/).
- Ruby: the script benchmarks under the **minimum** supported Ruby (from
  [`.minimum.tool-versions`](../.minimum.tool-versions)), matching CI — not the repo's
  default. (The default `.tool-versions` Ruby can be too new to boot the dummy app: Ruby 4.0
  trips `net-imap`'s `Ractor.make_shareable` and the server exits on startup.) On a `mise`
  machine this is automatic (the script sets `MISE_RUBY_VERSION`); otherwise make that Ruby
  the active one before running.
- The [`bencher`](https://bencher.dev/docs/explanation/bencher-run/) CLI on `PATH`.
- `BENCHER_API_KEY` exported (for uploads). This can be a project-scoped
  `bencher_run_...` key for this project or a user-scoped `bencher_user_...` key. For Pro
  suites, also `REACT_ON_RAILS_PRO_LICENSE`.
- Create the `m1-bench` testbed in the
  [`react-on-rails-t8a9ncxo`](https://bencher.dev/perf/react-on-rails-t8a9ncxo) Bencher
  project (or let the first upload create it). Its baseline is independent from the shared
  `github-actions` testbed — dedicated-hardware numbers are not comparable to shared-runner
  history, so they start a fresh series.

## Usage

```bash
# Full run of the core suite, upload to the m1-bench testbed:
BENCHER_API_KEY=… ruby benchmarks/run-local-benchmark.rb core

# Validate locally without touching Bencher:
ruby benchmarks/run-local-benchmark.rb core --no-upload

# Pro Rails suite, fail (exit 1) if a regression is flagged — useful as a release-candidate gate:
BENCHER_API_KEY=… REACT_ON_RAILS_PRO_LICENSE=… \
  ruby benchmarks/run-local-benchmark.rb pro --fail-on-alert

# Pro Node Renderer suite on the same dedicated testbed:
BENCHER_API_KEY=… REACT_ON_RAILS_PRO_LICENSE=… \
  ruby benchmarks/run-local-benchmark.rb pro-node-renderer --fail-on-alert

# Re-run against an already-built app (skip the build/setup steps):
ruby benchmarks/run-local-benchmark.rb core --no-setup --no-upload
```

Options: `--testbed NAME` (default `m1-bench`), `--branch NAME`, `--[no-]upload`,
`--fail-on-alert`, `--[no-]setup`, `--duration`, `--rate`, `--connections`. See `--help`.

## Quiet A/B comparisons

For release-candidate comparisons, do not trust a single `main` vs RC pass. Use the A/B
orchestrator so the machine is quiet before each run and each ref gets both early and late
positions in the sequence:

```bash
ruby benchmarks/run-local-benchmark-comparison.rb core \
  --a-ref v17.0.0.rc.5 --a-name rc5 \
  --b-ref origin/main --b-name main \
  --repetitions 5 \
  --no-upload
```

The comparison runner:

- creates temporary detached worktrees for both refs;
- installs the current local benchmark harness/reporting shim into those worktrees, so older RC
  tags can be measured without committing benchmark tooling into the tag;
- waits for a quiet machine window before each run (by default six consecutive samples, ten
  seconds apart, under the load/CPU thresholds shown in `--help`);
- alternates order by repetition (`A,B`, then `B,A`, then `A,B`, ...), reducing bias from
  warm caches, thermal drift, or background activity;
- writes per-run artifacts plus `comparison_summary.json` and `comparison_summary.md` under
  `bench_results/local_comparison/<timestamp>/`.

Comparison mode defaults to `--no-upload` because exploratory repeats can still be discarded.
When the machine was truly idle and the local summary is credible, add `--upload` to post every
repeat to the dedicated Bencher testbed. If a run becomes contaminated because you used the
machine during the benchmark, discard that artifact directory and rerun. For non-`main`
scenarios, the first upload still resets from `main` to clone thresholds, but later repetitions
append to the same Bencher branch/version so the comparison keeps all repeated samples.

Useful knobs:

```bash
# Print the plan only.
ruby benchmarks/run-local-benchmark-comparison.rb core \
  --a-ref v17.0.0.rc.5 --a-name rc5 \
  --b-ref origin/main --b-name main \
  --repetitions 3 \
  --dry-run

# Be stricter and wait up to 12 hours for a quiet window before each run.
ruby benchmarks/run-local-benchmark-comparison.rb core \
  --a-ref v17.0.0.rc.5 --a-name rc5 \
  --b-ref origin/main --b-name main \
  --repetitions 5 \
  --quiet-load-per-core 0.15 \
  --quiet-cpu-percent 12 \
  --quiet-timeout 43200
```

The script reuses the CI building blocks (no duplicated benchmark logic): per-suite config
from `generate_matrix.rb`, the dummy app's `bin/prod*` for the build + server, `bench.rb` for
the measurement, and `lib/bencher_runner.rb` for the upload (same tuned thresholds, with the
testbed overridden via `BENCHER_TESTBED`). It reports under the **checked-out git ref** (branch
name, or tag/SHA when detached) unless `--branch` overrides it: a nightly `main` run feeds the
dedicated main trend, while an RC tag or feature branch forms its own series instead of
polluting that baseline.

**Supported suites:** `core`, `pro` (Rails + k6), and `pro-node-renderer` (node renderer +
Vegeta). Run all three separately for a full benchmark pass; the Pro suites require
`REACT_ON_RAILS_PRO_LICENSE`.

## Posting results

Post enough context that another maintainer can tell whether the benchmark is usable without
re-running it:

- exact command, suite, refs, scenario names, repetitions, duration, and connection count;
- artifact directory path, especially `comparison_summary.md` and `quiet_samples.json`;
- whether upload was disabled or which Bencher testbed/branches received the upload;
- whether the machine stayed quiet for every run, or which runs were discarded;
- short interpretation of the largest candidate improvements/regressions and any route
  mismatch between the refs.

Do not post raw secrets, local environment files, or full terminal logs containing credentials.
For exploratory/noisy runs, post the local artifact path and say that the run was discarded
rather than uploading it to Bencher.

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
    <dict><key>BENCHER_API_KEY</key><string>…</string></dict>
    <key>ProgramArguments</key>
    <array>
      <string>/bin/bash</string><string>-lc</string>
      <string>git fetch origin &amp;&amp; git checkout origin/main &amp;&amp; ruby benchmarks/run-local-benchmark.rb core --branch main</string>
    </array>
    <key>StandardOutPath</key><string>/tmp/ror-benchmark.log</string>
    <key>StandardErrorPath</key><string>/tmp/ror-benchmark.err</string>
  </dict>
</plist>
```

Load it with `launchctl load ~/Library/LaunchAgents/com.shakacode.ror-benchmark.plist`. At
release-candidate time, run it by hand (optionally `--fail-on-alert`) against the RC ref.
