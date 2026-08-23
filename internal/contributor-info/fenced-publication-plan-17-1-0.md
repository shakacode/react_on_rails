# Fenced Publication Plan: 17.1.0.rc.0

This is the "explicit fully fenced reconciliation/publication plan covering
every outward write" required by the maintainer decision of 2026-08-23 as the
interim alternative to the repository-owned per-write lease wrapper. It
authorizes exactly one supervised execution of `bundle exec rake release` for
`17.1.0.rc.0` from `release/17.1.0`. It does not amend
[release-train-runbook.md](release-train-runbook.md); where they conflict, the
runbook wins and this plan must be corrected before use.

Maintainer approval of the PR that introduces this document is the go/no-go
for the single run it describes. Reusing the plan for a later cut requires
re-approval against that cut's context (head SHA, evidence run, version).

## Why a plan can substitute for the wrapper, for one run

The runbook's per-write lease re-verification exists to prevent interleaved
release-line writers. `rake release` is a compound writer that cannot re-check
the lease between its internal writes; the wrapper will fix that in code. For
a single supervised run, the same mutual-exclusion guarantee is achieved by:

1. one operator holding one continuously heartbeated claim on
   `release-line:17.1.0` for the entire run (fresh UUID identity, runbook
   procedure), and
2. releasing that claim only after every outward write below is verified or
   reconciled.

Both interactive OTPs (npm, RubyGems) force attended execution: the run cannot
proceed unattended past the publication boundary. The operator at the keyboard
is the crash detector.

This argument covers serialization only. It does not make the compound write
atomic - that is what the reconciliation matrix below is for.

## Preconditions (each verifiable, verify all on the day)

| # | Precondition | Verify with |
|---|---|---|
| P1 | `release/17.1.0` tip is the intended head | `git ls-remote origin release/17.1.0` = `0f405eeef...` (re-pin on approval day if the branch moved; any move re-runs CI + gate) |
| P2 | CHANGELOG stamped `### [17.1.0.rc.0]` at that tip | `git show origin/release/17.1.0:CHANGELOG.md \| grep -m1 '### \[17.1.0.rc.0\]'` |
| P3 | Full CI green on the exact tip | `gh run list --branch release/17.1.0 --json headSha,conclusion` - all workflows `success` on the tip SHA |
| P4 | ShakaPerf release-gate evidence for the tip | run `32630294983` (success, 2026-08-23); export `RELEASE_SHAKAPERF_RUN=32630294983` |
| P5 | Publish ownership on all six packages | `npm owner ls <pkg>` x4 contains `sasha_shakacode`; `gem owner <gem>` x2 contains `sasha@shakacode.com` |
| P6 | Local registry auth | `npm whoami` = `sasha_shakacode`; RubyGems key in `~/.local/share/gem/credentials` with `push_rubygem` scope |
| P7 | Coordination backend reachable | `agent-coord doctor --deep --json`: backend `http`, status `ok`, machine `sasha-macbook-pro` |
| P8 | Release-line lease held and live | runbook claim procedure + `require_live_release_line_lease` passes immediately before invocation |
| P9 | Background heartbeater running | refresh loop every 10 min, TTL 900 (heartbeat goes stale in 15 min; observed twice on 2026-08-23) |
| P10 | Fresh shell, no legacy selectors | `unset AGENT_COORD_BACKEND AGENT_COORD_REF AGENT_COORD_STATE_ROOT AGENT_COORD_STATUS_STATE_ROOT` |
| P11 | Dry run passes on the same head | `bundle exec rake "release[17.1.0.rc.0,true]"` completes with the expected file list |

## The outward-write ledger

`rake release` performs, in order (line references at `release.rake` of
2026-08-23; re-anchor if the file changes):

| W | Write | Where | Idempotent on re-run? |
|---|---|---|---|
| W1 | version-bump commit push to `release/17.1.0` | `git push` (~10093) | yes - "No version changes to commit" path skips a done bump |
| W2 | tag `v17.1.0.rc.0` push | `git push --tags` (~5393), behind tag-authorization and boundary guards | guarded - a matching tag at head is retry-safe; a tag at the WRONG sha aborts (see A2) |
| W3 | npm publish `react-on-rails@17.1.0-rc.0` | `publish_npm_with_retry` | yes, once W2 exists (see reconciliation model) |
| W4 | npm publish `react-on-rails-pro@17.1.0-rc.0` | same | same |
| W5 | npm publish `react-on-rails-pro-node-renderer@17.1.0-rc.0` | same | same |
| W6 | npm publish `create-react-on-rails-app@17.1.0-rc.0` | same | same |
| W7 | gem push `react_on_rails 17.1.0.rc.0` | `publish_gem_with_retry` | same |
| W8 | gem push `react_on_rails_pro 17.1.0.rc.0` | same | same |
| W9 | GitHub release for `v17.1.0.rc.0` from CHANGELOG | `sync_github_release_after_publish` | yes - `rake "sync_github_release[17.1.0.rc.0]"` is standalone and documented for already-published versions |

Blast-radius note: the npm dist-tag for `17.1.0-rc.0` resolves to `rc`
(`npm_dist_tag_for_version`), so no rc publication moves `latest`. The gems are
prereleases; RubyGems does not surface them as the default version.

OTP model: one npm OTP is requested and reused across W3-W6; the RubyGems OTP
is resolved up front and reused for W7-W8. Auth failures abort; only OTP
challenges and qualified transient network errors retry.

## Reconciliation model

The task's own resume mode is the primary mechanism:
`idempotent_publish_retry` turns on when the release tag already exists on the
remote at the current head. Therefore:

- **Crash before W1:** nothing outward happened. Re-run.
- **After W1, before W2:** bump commit is on the branch; re-run detects it
  ("No version changes to commit"), re-validates gates, continues to W2.
- **After W2, anywhere in W3-W8:** re-run from the same branch and head. The
  remote tag at head flips the run into idempotent retry mode: every
  already-published package answers "previously published" and is tolerated;
  missing ones are published. Do NOT hand-run `npm publish` or `gem push` to
  "finish" a partial state - always resume through the task so its guards and
  ordering apply.
- **After W8, before W9:** run `bundle exec rake "sync_github_release[17.1.0.rc.0]"`.
- **Verification failure after an apparently successful run:** treat as
  mid-W3-W8 crash; resume through the task.

Re-run rule: the resume MUST use the same branch, same head, and a live lease
(P8) re-verified immediately before invocation, same as the first attempt.

## Post-run verification matrix (all nine, in order, before releasing the lease)

```bash
git ls-remote origin release/17.1.0                                  # W1: new bump sha
git ls-remote origin refs/tags/v17.1.0.rc.0                          # W2: tag present, points at bump sha
npm view react-on-rails@17.1.0-rc.0 version                          # W3
npm view react-on-rails-pro@17.1.0-rc.0 version                      # W4
npm view react-on-rails-pro-node-renderer@17.1.0-rc.0 version        # W5
npm view create-react-on-rails-app@17.1.0-rc.0 version               # W6
npm dist-tag ls react-on-rails | grep '^rc:'                          # rc tag moved, latest untouched
curl -s https://rubygems.org/api/v1/versions/react_on_rails.json | jq -e 'any(.[]; .number=="17.1.0.rc.0")'       # W7
curl -s https://rubygems.org/api/v1/versions/react_on_rails_pro.json | jq -e 'any(.[]; .number=="17.1.0.rc.0")'   # W8
gh release view v17.1.0.rc.0 --json name,isDraft                     # W9
```

Only when all nine pass: release the claim (`agent-coord release ...`), then
announce (tracker #4842, Leslie, forward-port per runbook step 3).

## Abort conditions (stop, keep the lease, ping the maintainer; do not improvise)

- **A1:** any npm/gem rejection matching the task's registry-rejection
  patterns (`EPUBLISHCONFLICT`/`E403`/"cannot publish over"/"forbidden") that
  is NOT the idempotent already-published case.
- **A2:** the tag guard reports `v17.1.0.rc.0` existing at a DIFFERENT sha
  than the candidate. Never delete or move a pushed tag.
- **A3:** `require_live_release_line_lease` fails at any fence and one
  heartbeat refresh does not restore it.
- **A4:** any gate (CI status, ShakaPerf boundary, authorization digest)
  aborts inside the task. Overrides (`override_ci_status` etc.) are out of
  scope for this plan and require a separate maintainer decision.
- **A5:** anything not described in this document.

Rationale for keeping the lease on abort: a held lease is the only signal that
the line is mid-write; releasing it on a partial state invites a second writer
into exactly the situation the policy exists to prevent.

## Out of scope

Final `17.1.0` promotion (accepted-RC path), dist-tag corrections, yanking or
deprecating any published artifact, org/team changes, and every override flag.
Phase 2 - the repository-owned wrapper - should implement this document as
code, at which point this plan retires.
