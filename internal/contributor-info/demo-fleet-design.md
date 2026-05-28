# Demo Fleet Orchestrator — Design Sketch

**Status:** Draft, pending user review
**Date:** 2026-05-27
**Companion to:** [rc-testing-plan-design.md](rc-testing-plan-design.md)

## Purpose

Make cross-repo gem/npm bumps across the demo fleet repeatable and safe. Two modes:

1. **Release track** — triggered on `react_on_rails` / `shakapacker` / `react_on_rails_pro` / `cpflow` RC and final releases. Executes the RC PR cycle defined in the RC plan. Tier 1 demos hard-block the final release.
2. **Freshness track** — scheduled (weekly), bumps transitive deps within each demo to catch upstream breakage early. Tier 1 review-app smoke must pass; failures file issues, not block.

The orchestrator is the executor of the existing RC plan, not a parallel system. The RC plan owns policy (tiers, checklists, gating); this orchestrator owns mechanics (open PRs, bump lockfiles, wait for CI + review-app smoke, post results to the tracking issue).

## Layering

- **`react_on_rails` (this repo)** — owns the manifest ([demo-fleet.yml](demo-fleet.yml)), the RC plan, the orchestrator Rake tasks, and the tracking-issue template. Nothing in this repo opens cross-repo PRs at runtime by itself — see the credential model below.
- **Per demo repo** — owns its own CI, CPFlow review-app workflow, and Playwright smoke. The orchestrator dispatches and observes; it does not push CI definitions into demos.
- **No separate `react-on-rails-demos` repo, yet.** Defer until the orchestrator is stable here. When promoted, the manifest stays in `react_on_rails` (it's policy); only the runtime moves.
- **`reactonrails.com` is deliberately not the control plane.** It's a public documentation/marketing surface, not an operational repo. The control plane belongs in a contributor-only repo where credentials, manifests, and tracking issues already live.

## Manifest

Lives at [demo-fleet.yml](demo-fleet.yml). Schema documented in the file's header. Every entry currently carries `verify: true` because the per-demo `package_manager`, `smoke` paths, and `needs_pro` flags must be confirmed by inspecting each repo before the manifest is treated as authoritative — same convention as the RC plan's `*` markers.

The manifest captures **data**, not docs. Headlines and per-repo appendix text stay in the RC plan; the orchestrator only references the `headline` field for PR-body templating.

Package references are structured as `{ ecosystem: gem|npm, name: ... }`, not inferred from underscores or dashes. `DemoFleet` validates every package ref against the manifest's `age_gate.own_packages` set for ShakaCode-owned packages or against an explicit allowlist for third-party package bumps before it can compute registry lookups or lockfile updates.

## Orchestrator skeleton

Convention in this repo: orchestration lives in Rake (`rakelib/release.rake`), with `script/*` as a thin shim. Demo-fleet follows the same pattern.

### Rake tasks (`rakelib/demo_fleet.rake`)

```ruby
# Release track — invoked per RC and per final
task "demo_fleet:release_track", [:react_on_rails, :shakapacker, :react_on_rails_pro, :cpflow] do |_, args|
  fleet = DemoFleet.load("internal/contributor-info/demo-fleet.yml")
  versions = VersionSet.from_rake_args(args.to_h.compact) # keys match manifest package names
  tracking_issue = TrackingIssue.create_or_update(versions)
  target_repos = fleet.repos.select { |repo| repo.consumes?(versions.package_refs) }

  results = DemoFleet::Runner.run_concurrently(target_repos, concurrency: fleet.concurrency) do |repo|
    pr = DemoPR.open_or_update(repo, versions, mode: :release_track)
    pr.wait_for_ci_and_review_app(timeout: 90.minutes)
    pr.result
  end

  tracking_issue.record_all(results)
  tracking_issue.gate_check!  # fails if any hard_gate PR is red
end

# Freshness track — weekly scheduled
task "demo_fleet:freshness_track" do
  fleet = DemoFleet.load("internal/contributor-info/demo-fleet.yml")
  target_repos = fleet.repos.reject { |repo| DemoPR.open_release_pr?(repo) }

  results = DemoFleet::Runner.run_concurrently(target_repos, concurrency: fleet.concurrency) do |repo|
    proposed_bumps = DependencyBumps.compute(repo, age_gate: fleet.age_gate)
    next DemoResult.skipped(repo, "no permitted bumps") if proposed_bumps.empty?
    pr = DemoPR.open_or_update(repo, proposed_bumps, mode: :freshness)
    pr.wait_for_ci_and_review_app(timeout: 90.minutes)
    pr.result
  end

  results.each { |result| FreshnessIssue.file_if_red(result) unless result.green? } # freshness failures file issues, do not block
end

# Local-only: show what a release would propose, without opening anything
task "demo_fleet:plan", [:react_on_rails, :shakapacker, :react_on_rails_pro, :cpflow] do |_, args|
  # ...prints a table; no network mutations
end
```

### Shim (`script/demo-fleet`)

```bash
#!/bin/bash
# Thin shim — see `rake -D demo_fleet`
exec bundle exec rake "demo_fleet:${1:-plan}"
```

### Pieces the skeleton hides

- `DemoFleet` — manifest loader; validates `schema_version` and rejects unknown keys.
- `DemoFleet::Runner` — bounded parallel executor. It records per-repo exceptions as red `DemoResult` objects, keeps processing the remaining repos, and re-raises only after `tracking_issue.record_all` and `tracking_issue.gate_check!` have made the failure visible.
- `DemoPR` — opens/updates the bump PR in a demo repo via a GitHub App installation token (see Credentials). Generates the PR body from the RC plan's RC Test Report template, prefilled with the demo's manifest data.
- `DependencyBumps` — computes proposed version bumps with the age gate (next section).
- `TrackingIssue` — creates/updates the per-RC tracking issue in `shakacode/react_on_rails` from `.github/ISSUE_TEMPLATE/rc-release-tracking.yml`; ticks checkboxes as PRs land.
- `ReviewApp` — validates `review_app.cpflow_app_name`, polls GitHub Checks API for `review_app.status_check`, asks CPFlow for that app's review URL for the PR branch, and hits each `smoke` path against that base URL. It never derives the URL from the repo slug.
- `pr.wait_for_ci_and_review_app` — coordinates CI polling plus `ReviewApp` smoke checks.

### Parallel execution and failure recording

Release-track and freshness-track both dispatch repo work in parallel with a bounded concurrency limit (default 8, overridable by CI). Wall time is therefore capped by the slowest repo, not by `repos.count * 90.minutes`.

The runner treats each repo as an independent result. Network failures, rate limits, missing review-app checks, and timeouts are rescued at the repo boundary and recorded on the tracking issue as red results. The overall task can still exit non-zero after all repos have reported, but it must not abandon later repos or skip `gate_check!` because an earlier repo raised.

## Age-gate logic

The supply-chain defense. Uniform across package managers so policy is consistent — npm `minimumReleaseAge` is pnpm-only and recent, and Bundler has no native equivalent, so we don't rely on either.

### Inputs

- `age_gate.npm_min_days`, `age_gate.gem_min_days`, `age_gate.actions_min_days` from the manifest.
- `age_gate.own_packages.{npm,gem}` — our own packages bypass the gate on release-track runs.
- Mode (`:release_track` vs `:freshness`).

### Per-package decision

```ruby
def DependencyBumps.permitted?(package, candidate_version, mode:, age_gate:)
  min_days = age_gate.min_days_for(package.ecosystem)
  return true if mode == :release_track && age_gate.own?(package)

  published_at = Registry.published_at(package, candidate_version)
  age_days = (Time.now - published_at) / 86_400

  return true if age_days >= min_days

  return true if AgeGateOverride.active?(
    package,
    candidate_version,
    tracking_issue: ReleaseTrackingIssue.current,
    now: Time.now
  )

  false
end
```

### Registry lookups

- **npm** — `GET https://registry.npmjs.org/<pkg>` → `time[<version>]` is the publish timestamp. No auth required.
- **RubyGems** — `GET https://rubygems.org/api/v1/versions/<gem>.json` → array of `{number, created_at, yanked}`. Pick matching `number`. No auth required.
- **GitHub Actions** — `GET https://api.github.com/repos/<owner>/<repo>/releases/tags/<tag>` → `published_at`. Auth via the orchestrator's installation token.

Cache responses for the duration of a single orchestrator run (TTL 1h) to avoid hammering registries when many demos consume the same package.

### Why uniform-in-orchestrator instead of per-PM config

Demos in the fleet span pnpm, yarn classic, yarn berry, and bare npm (see manifest `package_manager` field). pnpm's `minimumReleaseAge` would only cover the pnpm demos and only after upgrading them all to pnpm 10+. The orchestrator computes bumps anyway (it has to know which versions to propose), so it's the natural enforcement point. Each demo's own Dependabot config keeps its `cooldown` for routine background updates; the orchestrator is the second layer for the bumps it drives.

### Defense-in-depth, not just the age gate

The age gate stops the orchestrator from introducing a too-young package, but it does not catch a package that is old enough yet known-vulnerable. Each demo's PR-side CI must also run [`actions/dependency-review-action`](https://github.com/actions/dependency-review-action) on every PR — it diffs the lockfile against the base branch and fails the PR if any newly-introduced dependency (direct or transitive) is on the GitHub Advisory Database. The orchestrator does not enforce this directly; instead, the demo-fleet manifest documents it as a required check, and the verification pass that clears `verify: true` flags also confirms each demo's CI runs the action.

Layers, in order:

1. **Per-demo Dependabot `cooldown`** — already in use in this repo (3-day default); catches routine background updates before they reach the orchestrator.
2. **Orchestrator age gate** — uniform across ecosystems for the bumps the orchestrator drives (7-day default; see `age_gate` in the manifest).
3. **Per-demo `dependency-review-action` on every PR** — fails the PR if any newly-introduced dep is vulnerable, regardless of age.
4. **Break-glass override** — labelled tracking issue, audited in the PR body (next section).

### Break-glass

For CVEs that need a sub-min-days patched version:

1. Release manager opens or updates a tracking issue in `shakacode/react_on_rails` titled `age-gate override: <pkg>@<version>`.
2. Issue body includes the CVE link, affected package, candidate version, and justification.
3. A second maintainer approves the override in an issue comment.
4. Release manager applies the `age-gate-override` label after approval. The orchestrator reads GitHub issue timeline events and uses the most recent label-applied timestamp as the start of the 7-day window; `updated_at` is not used because ordinary edits would extend the window accidentally.
5. `AgeGateOverride.active?` permits only the exact `ecosystem/name@version` named in the issue title/body and only while `now - label_applied_at <= 7.days`.
6. The override, approver, and expiry timestamp are logged in the tracking issue and in the resulting PR body.

This keeps audit trail in GitHub, not in shell history or env vars.

## Credentials

A ShakaCode GitHub App, installed on:

- `shakacode/react_on_rails` (read code, write issues/PRs)
- Every demo repo in the manifest (write contents for the bump branch, write PRs)
- The Pro gem source for repos with `needs_pro: true`

The orchestrator uses the App installation token. No long-lived PATs in CI.

Demos with `needs_pro: true` must additionally be able to `bundle install` the Pro gem during their own CI — that's a per-demo CI secret, not the orchestrator's problem, but the manifest flag is the discovery surface.

## Conflict policy

When the weekly freshness train runs and a demo has an open release-track PR:

- Freshness skips that demo for the cycle.
- Logged in the freshness summary so it's visible the demo was deliberately skipped, not silently missed.

When a release-track run lands while a freshness PR is open:

- Release-track takes priority. The orchestrator rebases or closes the open freshness PR (configurable per demo; default: close + reopen after the release-track PR merges).

## Cadence

- **Release track** — triggered manually by the release manager from `rake demo_fleet:release_track[X.Y.Z-rcN,A.B.C-rcM,...]` when an RC is cut, and again when the final ships. The post-release final-bump step in the RC plan is just `release_track` invoked with non-RC versions.
- **Freshness track** — GitHub Actions schedule, weekly, Monday 08:00 PT. Workflow at `.github/workflows/demo-fleet-freshness.yml` in this repo.

## Open items requiring user input

1. **Manifest verification owner.** Who runs the one-time pass to clear `verify: true` flags? Default: assigned during the next RC cycle, one demo per release manager.
2. **Pro gem source credential model.** Confirmed App installation, or do we need a separate machine user for the Pro source specifically?
3. **`react-on-rails-demos` promotion criteria.** What "stable" means before we move the runtime out of `react_on_rails`. Suggested: orchestrator has driven two consecutive successful RC cycles end-to-end without manual fixups.

## Out of scope (v1)

- Auto-generating per-demo Playwright smokes (covered by the RC plan's automation roadmap).
- Notifying Slack / Discord on freshness failures — start with GitHub issues; add chatops later.
- Cross-demo dependency dedup (e.g., harmonising React version across the fleet).

## Lifecycle

This file is a design spec. Once approved and the orchestrator lands, the canonical implementation lives in `rakelib/demo_fleet.rake` + `internal/contributor-info/demo-fleet.yml`. Delete this design doc in the implementing PR — same rule as `rc-testing-plan-design.md`.
