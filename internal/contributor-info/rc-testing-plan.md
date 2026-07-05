# RC Testing Plan

## Goal

Use one public `react_on_rails` tracking issue per final release target to decide whether the
current release candidate is ready to become the final release. The tracker records every RC
shipped to the hard-gate apps, the smoke evidence from those apps, any discovered regressions,
and the fresh final-version bump PRs after the final release ships.

This plan is contributor-only release process documentation. It lives in
`internal/contributor-info/` rather than public docs because it coordinates private release
validation, private app evidence, and maintainer-only go/no-go decisions.

## Release-Gate Model

### Hard Gates

The final release is blocked until every hard gate has passing smoke evidence, green required CI,
and no untriaged suspected RC regression.

| Gate                                            | Why It Blocks                                                                     | Minimum Evidence                                                                                                                                       |
| ----------------------------------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `react_on_rails` generator/install smoke        | Replaces the archived manual RSC generator demo with direct generator validation. | Generator specs pass, package build passes, and install smoke from local gems completes or has a filed blocker.                                        |
| `shakacode/hichee`                              | Private production-like app signal.                                               | High-level public tracker note that install/build/smoke/CI passed, with tester and date. Do not paste private logs, URLs, screenshots, or app details. |
| `shakacode/react-on-rails-demo-marketplace-rsc` | Public Marketplace RSC example.                                                   | RC bump PR, dependency install, app build/smoke, and CI status.                                                                                        |
| `shakacode/react-on-rails-demo-hacker-news-rsc` | Public Hacker News RSC example.                                                   | RC bump PR, dependency install, app build/smoke, and CI status.                                                                                        |
| `shakacode/react-on-rails-demo-gumroad-rsc`     | Public Gumroad RSC example.                                                       | RC bump PR, dependency install, app build/smoke, and CI status.                                                                                        |
| `shakacode/react-webpack-rails-tutorial`        | Public legacy tutorial reference.                                                 | RC bump PR, dependency install, primary tutorial route smoke, and CI status.                                                                           |
| `shakacode/react-on-rails-starter-tanstack`     | Public TanStack Pro + RSC starter example.                                        | RC bump PR, dependency install, starter build/smoke, and CI status.                                                                                    |

### Shelved Or Non-Gating Repos

Shelved repos are documented so they are remembered, but they do not block the final release and
do not require an RC bump unless someone explicitly chooses to work on them.

| Repo                                                       | Status                                                                                                        | Return-To-Gate Rule                                                                                                 |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `shakacode/react-on-rails-demo-ssr-hmr`                    | Shelved because it is very outdated. Follow-up: `shakacode/react-on-rails-demo-ssr-hmr#77`.                   | Modernize setup, dependencies, CI, and SSR/HMR smoke commands; then decide whether to promote it back to hard gate. |
| `shakacode/react-on-rails-example-migration`               | Shelved; value for the current final gate is uncertain.                                                       | Promote only if migration examples become a stated final-release gate.                                              |
| `shakacode/react-on-rails-example-open-flights`            | Shelved; useful reference, but not a current blocker.                                                         | Promote only after it has durable smoke coverage and maintainers want migration references to block final.          |
| `shakacode/react-on-rails-demo-v16-bundle-splitting`       | Shelved; inherited from an older RC spec, not part of the current public-example gate.                        | Promote only if it becomes a current major example again.                                                           |
| `shakacode/react_on_rails-demo-octochangelog-on-rails-pro` | Non-gating for the current plan; useful Pro/RSC signal but not part of the approved public-example hard gate. | Promote only if maintainers want this Pro demo to block final releases again.                                       |
| `shakacode/react-on-rails-rsc-demo`                        | Retired and archived; it mainly represented a manual generator run.                                           | Do not promote. Validate this surface through `react_on_rails` generator/install smoke instead.                     |

## Tracking Issue Lifecycle

Create one tracking issue per final release target, not one issue per RC.

Recommended title:

```text
Release gate: react_on_rails X.Y.Z
```

The issue stays open from the first RC through final-version bump completion. If there are
multiple RCs for the same final release, add a new RC section inside the same issue.

The tracking issue is the single source of truth for:

- package versions under test
- hard-gate PR links
- smoke commands and evidence
- required CI status
- advisory AI review status
- suspected RC regressions
- explicit waivers for unrelated failures
- fresh final-version bump PRs
- final go/no-go decision

## RC Validation Workflow

1. Cut the RC packages.
2. Create or update the release-gate tracking issue from
   `.github/ISSUE_TEMPLATE/rc-release-tracking.yml`.
3. Open RC bump PRs in every hard-gate app that consumes the changed package.
4. Run local smoke where practical before relying on CI.
5. Record evidence in the tracking issue for each hard gate.
6. File issues for every suspected RC regression or blocked smoke path.
7. Treat AI review checks as advisory unless they identify a real bug.
8. Make the final go/no-go call only after every hard gate is green or explicitly waived.

## Required Pass Criteria

For each hard-gate app PR:

- dependency install succeeds for the repo's package manager
- lockfiles are updated consistently
- app build or asset compile succeeds
- the repo's required CI checks are green
- the release manager records exact smoke evidence in the tracking issue
- any suspected RC regression is filed as an issue before final

For the `react_on_rails` generator/install gate:

```bash
bundle exec rspec react_on_rails/spec/react_on_rails/generators
pnpm run build
CREATE_ROR_SMOKE_SCOPE=oss packages/create-react-on-rails-app/scripts/smoke-test-local-gems.sh
```

If a command fails for an environmental reason, record the failure and file or link a follow-up
issue. Do not silently mark the gate as passed.

## Advisory Checks

AI review checks, including Claude, CodeRabbit, Cursor Bugbot, and similar tools, are advisory
unless they report a real actionable bug.

Use this rule:

- **Actionable product/build bug**: fix or file an issue before final.
- **Workflow/auth/tooling failure**: record in the tracker, file an issue if needed, and do not let
  it silently block or silently pass.
- **Style-only or noisy review**: record as advisory; it does not block final.

## Waivers

A hard gate can be waived only when the failure is proven unrelated to the RC or final package.
The tracker comment must include:

- gate name
- failed command or check
- why it is unrelated to the RC
- issue link for the unrelated failure
- maintainer/date approving the waiver

Do not self-certify ambiguous RSC, build, or generator failures. If the failure could plausibly be
caused by the RC, treat it as a release blocker until another maintainer agrees it is unrelated.

## HiChee Privacy Rule

`shakacode/hichee` is a private hard gate, but the tracker is public. The public tracker may name
the repo and record high-level status, but it must not expose private app details.

Allowed public evidence:

- PR link, if acceptable to maintainers; GitHub hides private PRs from people without access
- install/build/smoke/CI passed
- tester name and date
- a high-level note that a private issue was filed

Not allowed in the public tracker:

- private logs
- private URLs
- screenshots
- customer data
- internal app behavior details
- secrets or environment variable names that reveal sensitive infrastructure

## Final Release And Final Bumps

After the final `react_on_rails` release ships:

1. Open fresh final-version bump PRs in the hard-gate apps.
2. Do not rely on renamed RC PRs unless there is unusual review history worth preserving.
3. Re-run CI and minimum smoke on each final bump PR.
4. Merge final bump PRs.
5. Close the release-gate issue only after every hard-gate final bump is merged or has an explicit
   follow-up issue.

The clean default is two PRs per hard-gate app:

- an RC PR that proves readiness
- a final PR that proves the app is no longer pinned to an RC

## RC Test Report Template

Paste this into each hard-gate app PR body and fill it in as evidence arrives.

```markdown
## RC Test Report

Tracking issue: shakacode/react_on_rails#<issue-number>

### Versions

- react_on_rails gem:
- react-on-rails npm:
- react_on_rails_pro gem, if used:
- react-on-rails-pro npm, if used:
- shakapacker gem/npm, if changed:
- cpflow, if changed:

### Automated Checks

- [ ] Dependency install passes:
- [ ] Lockfile update is intentional:
- [ ] App build or asset compile passes:
- [ ] Required CI is green:
- [ ] Advisory AI review checks recorded:

### Smoke Evidence

- [ ] Primary route loads:
- [ ] Server-rendered output is present where expected:
- [ ] RSC or client interaction works for this repo's headline feature:
- [ ] Browser console has no new red errors:
- [ ] Any known unrelated failures are linked:

### Result

- [ ] Passed and linked in the release-gate tracker
- [ ] Blocked by suspected RC regression, issue:
- [ ] Waived as unrelated to RC, tracker comment:
```

## Tracking Issue Template

Use `.github/ISSUE_TEMPLATE/rc-release-tracking.yml` to create the release-gate issue. The issue
form intentionally asks for:

- final release target
- package versions under test
- hard-gate table
- shelved repo notes
- RC-by-RC results
- final bump status
- final go/no-go decision

## Automation Roadmap

The plan is intentionally manual-first. Automation should fill in evidence, not own release policy.

Future automation can:

- open or update hard-gate bump PRs
- fill automated CI and smoke sub-items in the tracking issue
- poll review-app URLs where available
- detect stale RC pins after final ships
- report advisory AI review status

Automation must not:

- make the final go/no-go decision
- hide private HiChee evidence in public logs
- promote shelved repos back to hard gate without maintainer approval
- waive suspected RC regressions without a maintainer comment
