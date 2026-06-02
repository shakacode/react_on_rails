# Main CI release guard + continuous monitoring

**Status**: Implemented (see PR #3407)
**Date**: 2026-05-25
**Owner**: Justin Gordon (with Claude Code)

## Problem

CI on `main` has been failing for the last 8+ push commits, primarily on:

- **JS unit tests for Renderer package** — `tests/tanstackRouter.test.ts:1669` (regression from #3213)
- **Benchmark Workflow** — port 3001 + missing summary file (#3403 attempted, insufficient)

Today, nothing blocks a release from going out on top of a broken `main`. Nothing makes an AI coding agent (or human) notice that `main` is red before opening a PR on top of it.

This design adds two guards:

1. **Release-time gate**: `rake release` refuses to publish when CI on `main` isn't healthy, unless explicitly overridden.
2. **Session-time signal**: every Claude Code session gets `main`'s CI status injected at start (and again before pushing to `main` / opening a PR).

The actual CI failures are tracked in separate issues (filed as part of this work) and will be fixed in separate PRs by parallel Conductor worktrees.

## Scope

This PR delivers:

- `rakelib/release.rake` — new CI status check + override
- `release_rake_helpers_spec.rb` — tests for the new check
- `.claude/hooks/main-ci-status.sh` — hook script that prints `main` CI status
- `.claude/settings.json` — wire the hook into `SessionStart` and `PreToolUse`
- `AGENTS.md` — new "Main branch health" section
- `CLAUDE.md` — one-line pointer to the AGENTS.md section
- Two GitHub issues filed (tanstackRouter regression, Benchmark Workflow), each ready for a parallel worktree

Out of scope:

- Fixing the tanstackRouter test (separate worktree, separate PR)
- Fixing the Benchmark Workflow (separate worktree, separate PR)
- Branch-protection policy changes on GitHub itself
- Any change to the merge / PR-open flow (e.g., bot comments)

## Design — Section 1: Release-time CI gate

### Where it runs

In `rakelib/release.rake`, inside `run_release_preflight_checks!`, after `verify_npm_auth` and `verify_gh_auth`. We already know which version we're shipping by this point and we have a verified `gh` session.

Note: `run_release_preflight_checks!` runs _before_ `with_release_checkout` (and therefore before its `git pull --rebase`). The CI check must run `git fetch origin main --quiet` itself to ensure it's evaluating the latest `origin/main` SHA, not whatever the local refs happen to be.

### Public API

The `:release` task gets a new 4th positional argument and a paired env var, paralleling the existing `override_version_policy`:

```ruby
task :release, %i[version dry_run override_version_policy override_ci_status]
```

```bash
RELEASE_CI_STATUS_OVERRIDE=true   # bypass the CI status check
```

The task description gets corresponding doc lines.

### Policy

The check first fetches `origin/main`, then evaluates the CI status of `origin/main` HEAD:

- **Stable release** (no `.test.` / `.beta.` / `.alpha.` / `.rc.` / `.pre.` in target version):
  Every check run on the commit must have `conclusion ∈ {success, skipped, neutral}`. Any other conclusion (failure, cancelled, timed_out, action_required, stale) → block. Any check still `status: in_progress` or `queued` → block. Zero check runs visible → block (we may be looking too early; the user can override).

- **Pre-release** (RC / beta / alpha / pre / test):
  Same rule, but restricted to the _required_ status checks as defined by GitHub branch protection (`gh api repos/.../branches/main/protection/required_status_checks`). Non-required checks are advisory and do not block. If branch protection isn't queryable (no protection configured, or insufficient token scope), fall back to the stable rule (treat all checks as required — fail safe).

The target commit is **always `origin/main` HEAD**, regardless of where the release is being run from. Even pre-releases shouldn't ship when `main` is broken.

### Failure UX

When blocked, the error names the failing checks, links to them, and tells the operator exactly how to proceed:

```text
❌ CI on main is not healthy — refusing to release.

Commit: 3103496d
  ❌ failure: JS unit tests for Renderer package
      https://github.com/shakacode/react_on_rails/actions/runs/26404417346
  ❌ failure: Benchmark Workflow
      https://github.com/shakacode/react_on_rails/actions/runs/26404417325

To override (use only if the failures are known-unrelated to this release):
  RELEASE_CI_STATUS_OVERRIDE=true bundle exec rake release[...]
  # or
  bundle exec rake "release[16.2.0,false,false,true]"
```

In-progress checks get a separate message ("CI in progress — wait for it to finish, or override").

### Dry-run behavior

Dry runs still run the check (so the operator sees the same diagnostic), but never abort. A red `main` in a dry-run prints a warning so the operator knows the real release would block.

### Code shape

Mirror the existing version-policy helpers:

```ruby
def ci_status_override_enabled?(override_flag)
  ReactOnRails::Utils.object_to_boolean(override_flag) ||
    ReactOnRails::Utils.object_to_boolean(ENV.fetch("RELEASE_CI_STATUS_OVERRIDE", nil))
end

def fetch_main_ci_checks(monorepo_root:)
  # 1. `git fetch origin main --quiet`
  # 2. resolve origin/main SHA (`git rev-parse origin/main`)
  # 3. `gh api repos/{owner}/{repo}/commits/{sha}/check-runs --paginate`
  #    NB: this is the GitHub Checks API (used by Actions). We do NOT need
  #    the legacy Statuses API (`/commits/{sha}/status`) — all our CI runs
  #    through GitHub Actions, which reports via Check Runs.
  # Returns: { sha:, check_runs: [{name, status, conclusion, html_url}, ...] }
end

def required_check_names_for_main(monorepo_root:)
  # `gh api repos/{owner}/{repo}/branches/main/protection/required_status_checks --jq '.contexts'`
  # Returns nil if no branch protection (caller treats as "all required").
end

def validate_main_ci_status!(monorepo_root:, is_prerelease:, allow_override:, dry_run:)
  # Apply policy, format error, abort or warn.
end
```

### Tests

`react_on_rails/spec/react_on_rails/release_rake_helpers_spec.rb` gets new contexts that stub `Open3.capture2e`/`gh` calls:

- all-success → passes
- one failure on a required check → blocks (raises)
- failure on a non-required check, prerelease → passes (advisory only)
- failure on a non-required check, stable → blocks
- check still in_progress → blocks with "in progress" message
- zero check runs visible → blocks with "no CI data" message
- override env var set → warns, returns
- override arg set → warns, returns
- branch protection query fails → falls back to "treat all as required"
- `gh` command failure → propagates the error verbatim (no silent override)

### Edge cases and tradeoffs

- **What if the operator wants to release from a commit other than `origin/main` HEAD?**
  Today the release task already runs `git pull --rebase` (line 910) on the release worktree. By the time we check, HEAD will be `origin/main` HEAD. Releasing from elsewhere is an explicit override situation.
- **Why not check the _local_ commit being tagged?**
  Stable releases create their own version-bump commit _on top of_ `origin/main`; that commit hasn't been pushed yet when we check. The question we're answering is "is the foundation we're building on healthy?", which is exactly what `origin/main` HEAD tells us.
- **Why not poll/wait for in-progress checks?**
  Discussed and rejected: forces a deliberate "wait or override" decision instead of embedding a polling loop in the release script. Operators who want polling can use `gh run watch` themselves.
- **Why query `required_status_checks` instead of a hardcoded allowlist?**
  Branch protection is already the source of truth for "what counts as mergeable." Reusing it avoids drift between two policy lists. If no branch protection exists, we degrade safely (treat everything as required).

---

## Design — Section 2: Continuous CI monitoring

### `.claude/hooks/main-ci-status.sh`

A small bash script that queries `gh api repos/{slug}/commits/{sha}/check-runs` (the GitHub Checks API, not `gh run list`) and emits a compact status block:

```text
Main CI status (3103496d, pushed 7h ago):
  ✅ 11 success
  ❌ 2 failure:
     - JS unit tests for Renderer package: https://github.com/shakacode/.../runs/...
     - Benchmark Workflow:                 https://github.com/shakacode/.../runs/...
  ⏳ 0 in_progress
```

Behavior:

- Output goes to stdout (the harness injects it as additional context).
- Exits 0 always. Tooling failures (no `gh`, no auth, no network) print a one-line "main CI status unavailable: <reason>" and exit 0. We never block a session because the status check failed.
- Caches to `.claude/.main-ci-status.cache` for 5 minutes — repeated session starts in the same window reuse the cached output instead of hitting the GitHub API every time.

### `.claude/settings.json` wiring

- `hooks.SessionStart` — runs the script unconditionally.
- `hooks.PreToolUse` — runs the script when the next command matches:
  - `gh pr create` (any args)
  - `git push` to `origin main` or `origin HEAD` (regex-matched)

The PreToolUse trigger uses a glob/regex on `tool_input.command` to avoid running on every Bash call.

### Prose changes

**`AGENTS.md` (canonical)** gets a new section after "Boundaries":

```markdown
## Main branch health

The `main` branch must stay green. CI failures on `main` block releases (see
`rakelib/release.rake` — the release task refuses to publish over a red `main`
without an explicit override).

Every Claude Code session starts with a CI-status block for the latest `main`
push commit, and the same block is re-emitted before `gh pr create` or pushing
to `main`. Read it.

If `main` is red:

1. Decide whether the failure is related to your work. If yes, your job is to
   fix it (or revert) before adding new commits.
2. If unrelated, decide whether your work is safe to merge on top. PRs that
   add risk on top of a known-broken `main` should usually wait.
3. If you're the one merging a PR, check `main` post-merge within 30 minutes
   (see `.claude/docs/main-health-monitoring.md`).

**Never silently override the release CI gate.** If you `RELEASE_CI_STATUS_OVERRIDE=true`,
document in the PR / release notes why the red checks are unrelated to the release.
```

**`CLAUDE.md`** gets one new line under "Behavioral Defaults":

```markdown
- Check main CI status at session start (the hook injects it) and again
  before `gh pr create` or pushing to main. See `AGENTS.md` → Main branch
  health.
```

### Tests / verification

- Run the hook script manually after install: `.claude/hooks/main-ci-status.sh` should print a status block and exit 0.
- Disconnect from network, re-run: should print "unavailable" message and exit 0 (does not break).
- Start a new Claude Code session: status block appears in the session-start system reminder context.
- `gh pr create --dry-run`: PreToolUse hook fires (verify in transcript).

---

## Issues to file (PR #2 and PR #3)

The CI failures are out of scope for this PR but get full GitHub issues so parallel Conductor worktrees can pick them up cold. The bodies follow the "observations + leading hypotheses" pattern: definitive facts come first, then labeled hypotheses that future investigators can keep or discard.

### Issue for PR #2 — tanstackRouter `loadRouteChunk` double-call under StrictMode

**Title**: `fix(tanstack-router): loadRouteChunk called 2× under StrictMode hydration replay`

**Body (sketch)**:

```markdown
## Observed

`packages/react-on-rails-pro/tests/tanstackRouter.test.ts:1669` fails on every
push to `main` as of #3213:

    ● tanstack-router integration (Pro) ›
      does not double-call loadRouteChunk when StrictMode replays hydration effects

      expect(jest.fn()).toHaveBeenCalledTimes(expected)
        Expected: 1
        Received: 2

Implementation under test: `packages/react-on-rails-pro/src/tanstack-router/clientHydrate.ts`,
specifically the `routerRef.current === null` block (line ~186) which calls
`preloadMatchedRouteChunks` → `loadRouteChunk`.

Introduced by [PR #3213](https://github.com/shakacode/react_on_rails/pull/3213)
("remove Suspense gate around RouterProvider during hydration"). The failing
test was added in that PR as a regression guard.

## Repro

    cd packages/react-on-rails-pro
    pnpm test -- tests/tanstackRouter.test.ts \
      -t "does not double-call loadRouteChunk when StrictMode"

## Leading hypotheses (not verified)

1. **StrictMode mount/unmount/mount cycle resets `routerRef`.** In React 18 dev
   StrictMode, components are mounted, unmounted, and re-mounted. `useRef`
   instances are per-component-instance, so the second mount sees
   `routerRef.current === null` and re-enters the init block — calling
   `preloadMatchedRouteChunks` a second time. If correct, either:
   - the test's expectation is wrong (should be 2) and the comment at
     `tanstackRouter.test.ts:1665-1668` describes a guard that doesn't actually
     work across remount; or
   - the implementation needs a guard that survives unmount (module-level
     `WeakSet` keyed on the router instance? Or a guard on `options.createRouter`
     identity?).

2. **A render-phase double invocation within a single mount.** Less likely given
   the `routerRef.current === null` guard, but possible if React discards a
   render mid-init and the second render finds the ref still null because the
   first render's assignment was discarded.

Inspect the `routerRef.current = router` assignment (clientHydrate.ts:300) and
the surrounding "Safety invariant" comment (lines 192-196) — the comment
explicitly addresses discarded renders but may not address StrictMode remount.

## Acceptance criteria

- `tests/tanstackRouter.test.ts` test "does not double-call loadRouteChunk
  when StrictMode replays hydration effects" passes.
- Other tanstackRouter tests still pass.
- Either the implementation enforces "one preload per (router instance,
  hydration payload)" across mount cycles, _or_ the test expectation is
  corrected with a code comment explaining why double-call is acceptable.
- CHANGELOG.md gets an entry (Fixed, Pro) if user-visible.

## Out of scope

- Broader hydration refactors.
- Changes to non-tanstackRouter integration paths.
```

### Issue for PR #3 — Benchmark Workflow port + summary failures

**Title**: `fix(ci): Benchmark Workflow fails — bench.rb doesn't produce summary, port 3001 never frees`

**Body (sketch)**:

```markdown
## Observed

`Benchmark Workflow` fails on every push to `main` as of at least 8 commits ago.

Two error messages at the end of the failing run:

    ❌ ERROR: benchmark summary file not found        (from "Validate Core benchmark results")
    ❌ ERROR: Port 3001 is still in use after 10 seconds  (from "Stop Core production server")

K6 output earlier in the run shows `checks_failed: 75%` across many phases,
suggesting the production server isn't responding cleanly under load.

Workflow file: `.github/workflows/benchmark.yml` (steps "Execute Core benchmark
suite" through "Stop Core production server").

## What's already been tried

[PR #3403](https://github.com/shakacode/react_on_rails/pull/3403)
("Better specify `PORT` in `prod` scripts to fix the benchmark workflow") set
`PORT=3001` in both `react_on_rails/spec/dummy/bin/prod` and
`react_on_rails_pro/spec/dummy/bin/prod` so Foreman doesn't default to
`PORT=5000`. The workflow still fails after that change.

Commits where the workflow has failed include 3103496d (post-#3403),
33bacf90, 4758078165, c611361e, fb174e5d, fcc817d2. (`gh run list --branch main
--event push --json conclusion,headSha,workflowName --jq '...'`.)

## Repro

Trigger the workflow via `gh workflow run benchmark.yml` against `main`, or
push any non-docs commit to `main`.

For a local-ish repro:

    cd react_on_rails/spec/dummy
    bin/prod-assets
    PORT=3001 bin/prod &
    # wait for http://localhost:3001
    bundle exec ruby benchmarks/bench.rb
    ls bench_results/

## Leading hypotheses (not verified)

1. **The Core server starts but doesn't survive the benchmark load.** The 75%
   k6 check-failure rate suggests the server is failing to respond to most
   requests. If it crashes, `bench.rb` may not write `bench_results/summary.txt`
   on the way out. Investigate whether `bench.rb` writes the summary
   incrementally or only at end, and whether the server logs show OOM /
   worker crash patterns.

2. **`pkill -9 -f "ruby|node|foreman|overmind|puma"` is too broad / too late.**
   If the benchmark step exited via `set -e` because of the upstream failure,
   the "Stop" step might be killing processes that have already crashed in
   ways that leave port 3001 in `TIME_WAIT`. Worth checking what `lsof
-i:3001` actually shows.

3. **Concurrent server processes.** The Core server starts, runs benchmarks,
   then we expect to stop it before starting Pro on the same port. If Foreman
   spawns child processes that survive `pkill`, the second `Start Pro
production server` step would find 3001 occupied even after the kill loop.
   (#3403 may have helped or may have made this worse — the Pro server now
   _also_ binds 3001 explicitly via `bin/prod`.)

## Acceptance criteria

- A push to `main` (non-docs) sees the Benchmark Workflow complete with
  `conclusion: success` (or, if a regression is detected, with the warn-only
  path on main per the existing step 7c — not a hard failure on operational
  errors).
- `bench_results/summary.txt` is produced when `RUN_CORE` is true.
- Port 3001 reliably frees within the existing 10-second window between Core
  and Pro server steps.

## Out of scope

- Tuning bencher thresholds (the t-test config is fine).
- Migrating off Foreman / overmind.
- Adding new benchmark scenarios.
```

---

## Risks and mitigation

| Risk                                                         | Mitigation                                                                                   |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| Hook adds latency to every session start                     | 5-min cache; gh CLI is fast (<1s); fail-open if slow                                         |
| Release gate blocks a legitimate hotfix                      | Override env var is documented in the error message itself                                   |
| GitHub branch protection API call requires extra token scope | Falls back to "treat all checks as required" if query fails                                  |
| The hook script bug breaks every session                     | Fail-open: any script error → prints "unavailable" and exits 0                               |
| `gh` not authenticated on a contributor's machine            | Hook prints unauthenticated message; release gate aborts with clear error (existing pattern) |

## Open questions

None remaining at design time — the user has confirmed:

- Required-checks (A) for rc; every check (C) for stable releases
- Override via env var + 4th positional arg, paralleling existing version-policy override
- In-progress checks block (no polling)
- Always check `origin/main` HEAD, regardless of where the release runs from
- Hook-driven signal _and_ prose docs
- Three separate PRs (this is PR #1; #2 and #3 file as issues for parallel worktrees)
- Issue format: observations first, then labeled hypotheses

## Next step

Invoke `writing-plans` skill to produce an executable implementation plan for this PR.
