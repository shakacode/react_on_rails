# Self-hosted benchmark runner

The shared GitHub-hosted runners can't produce a trustworthy microbenchmark signal: CPU
contention from noisy neighbors causes ±50–125% bidirectional swings, which fired five
false-positive regression issues in one evening (#4038–#4044, see #4071). A dedicated,
always-on machine that does nothing else removes that variance, so its numbers are stable
enough to gate a release candidate.

Tracking issue: **#4073**. This doc describes what exists today and what remains before a
self-hosted RC/nightly workflow can run.

## What this provides today (foundation)

The reusable benchmark suite ([`benchmark-suite.yml`](../.github/workflows/benchmark-suite.yml))
is now parameterized so the _same_ suite the cloud path uses can run on an alternate runner
with its own baseline and act as a gate — no duplicated benchmark logic:

| Input           | Default            | Purpose                                                                                                                                                                                                                                                              |
| --------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `runs_on`       | `["ubuntu-24.04"]` | JSON label set for the suite job — point it at a self-hosted runner.                                                                                                                                                                                                 |
| `testbed`       | `github-actions`   | Bencher testbed (read via `BENCHER_TESTBED` in [`bencher_runner.rb`](lib/bencher_runner.rb)). A dedicated runner reports to its own testbed (e.g. `m1-bench`) so its arm64 numbers build a separate baseline — they are **not comparable** to shared-runner history. |
| `fail_on_alert` | `false`            | When true, a Bencher regression fails the job (`BENCHMARK_FAIL_ON_ALERT` in [`track_benchmarks.rb`](track_benchmarks.rb)), so a gated RC/nightly run blocks on a regression. Main-push runs are unaffected (they keep the candidate/confirmation flow).              |

All three default to current behavior, so the existing cloud workflow is unchanged.

The suite's OS-specific steps are also portable: Vegeta installs the right OS/arch build via
`curl`, CPU count comes from `sysctl` on macOS (`nproc` on Linux), CPU pinning (`taskset`) is
skipped where it's unavailable, and the `/etc/issue` diagnostic falls back to `uname`. The
Linux path is byte-for-byte unchanged. Validated on an Apple Silicon machine: the Vegeta
`darwin_arm64` build installs and runs, `sysctl` core detection and the no-`taskset` fallback
work, and the Bencher CLI installer supports `aarch64-apple-darwin`.

## Remaining before a self-hosted workflow runs

The workflow itself (RC-tag + nightly triggers calling the suite on the dedicated runner) is
intentionally **not** added yet:

1. **Register the runner** (below).
2. Add the workflow targeting it with `workflow_dispatch` first, so a maintainer can validate
   one real end-to-end run on the live machine before enabling the automatic triggers.

## Security: this is a public repository

GitHub [recommends against](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners#self-hosted-runner-security)
self-hosted runners on public repos, because a fork pull request can run arbitrary code on
your machine. The planned workflow avoids that:

- It will run **only** on maintainer-controlled events (`workflow_dispatch`, then RC tag
  pushes and a nightly schedule) on already-merged code — **never `pull_request`**, so fork
  PRs can never execute on the machine.
- Set repo → Settings → Actions → General → "Fork pull request workflows from outside
  collaborators" to **require approval for all outside collaborators** (defense in depth).
- Use a dedicated machine with nothing else of value on it, ideally on an isolated network
  segment. Store no secrets on it beyond what the Pro dummy app needs.

## One-time machine setup (for when the workflow lands)

1. **Install the toolchain** (match the repo's pinned versions):
   - Ruby per [`.tool-versions`](../.tool-versions) (rbenv/asdf), plus Bundler.
   - Node per `.tool-versions`, and `pnpm` (via `corepack enable` or `npm i -g pnpm`).
   - [`k6`](https://grafana.com/docs/k6/latest/set-up/install-k6/) (the benchmark driver).
   - The [`bencher`](https://bencher.dev/docs/explanation/bencher-run/) CLI.
2. **Register the runner**: repo → Settings → Actions → Runners → New self-hosted runner.
   Follow the macOS/arm64 instructions and add the labels the workflow will target, e.g.:

   ```
   self-hosted, macOS, ARM64, rork-bench
   ```

   Install it as a service (`./svc.sh install && ./svc.sh start`) so it is always listening.

3. **Confirm secrets** (already set for CI, used by the reusable suite): repo →
   Settings → Secrets → Actions has `REACT_ON_RAILS_PRO_LICENSE_V2` and `BENCHER_API_TOKEN`.
4. **Create the Bencher testbed** named `m1-bench` in the
   [`react-on-rails-t8a9ncxo`](https://bencher.dev/perf/react-on-rails-t8a9ncxo) project
   (or let the first `--testbed m1-bench` run create it). It starts a fresh baseline series,
   independent from the shared `github-actions` testbed.
