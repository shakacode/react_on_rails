# Fenced Publication Plan: 17.1.0.rc.0

This is the "explicit fully fenced reconciliation/publication plan covering
every outward write" required by the maintainer decision of 2026-08-23 as the
interim alternative to the repository-owned per-write lease wrapper. It
requests approval for exactly one supervised execution of
`bundle exec rake release` for `17.1.0.rc.0` from `release/17.1.0`.

Maintainer approval of the PR that introduces this document is the go/no-go
for the single run it describes, including the explicit policy exception in
the next section. Reusing the plan for a later cut requires re-approval
against that cut's context (head SHA, evidence run, version).

## What the runbook prohibits, and what this plan requests

[release-train-runbook.md](release-train-runbook.md) ("compound writer"
guidance) prohibits live use of `bundle exec rake release`: a compound helper
cannot check lease ownership at each outward-operation boundary, a separate
supervisor is insufficient because it can die while the helper continues, and
the runbook's instruction for that case is to stop rather than run an
uncontrolled compound writer.

This plan does not claim to satisfy that requirement. `rake release` cannot be
decomposed into individually fenced outward writes from the outside, so a
fully compliant live rc.0 is impossible until the wrapper exists. The plan
therefore requests a one-run policy exception, with the residual risk stated
precisely and compensated as far as a supervised run allows:

**Fences that do hold:**

- One operator, one fresh UUID coordinator identity, one claim on
  `release-line:17.1.0` acquired via the runbook procedure, verified with
  `require_live_release_line_lease` immediately before invocation.
- Dual renewal per the runbook: heartbeat refreshed **every 5 minutes** (TTL 900) and the claim itself renewed **at least hourly** with the bounded
  `claim` command, both by one background loop for the entire run.
- Interactive OTP prompts act as mid-run manual fences: before entering the
  npm OTP (W4 boundary) and before EVERY RubyGems OTP prompt - the initial
  W8-boundary prompt and any replacement prompt `publish_gem_with_retry`
  issues when the TOTP window expires between the two gem pushes - the
  operator re-runs `require_live_release_line_lease` in a second shell and
  types the code only on a pass. Both prompt positions are
  verified against `release.rake` (npm: first publish challenge; RubyGems:
  `resolve_rubygems_otp_for_publish` immediately before the gem pushes).
- Fail-closed watchdog: the renewal loop runs in a second shell and records
  the `rake` PID at invocation. On any failed heartbeat or claim renewal it
  sends `SIGINT` to that PID immediately - the same signal as an operator
  Ctrl-C. Termination at any point, including mid-write, is recoverable by
  design (see reconciliation model: a single interrupted write either landed
  or did not, and the resume path covers both). Lease loss therefore stops
  the helper within one renewal interval instead of letting it run on.

**Residual unfenced windows (the exception being approved):**

- R1: W1 through W3 (bump push, tracker comment, tag push) run without an
  interactive pause after invocation.
- R2: W4 through W7 (four npm publishes) after the npm OTP is entered.
- R3: W8 through W9 (two gem pushes) after the RubyGems OTP is entered.
- R4: W10 (GitHub release) after W9.

Within these windows there is no interactive pause, so ownership is not
re-checked between consecutive writes; the watchdog bounds a lease loss to
one renewal interval (at most 5 minutes) rather than eliminating the window.
If the watchdog itself dies, that residual case is covered only by the
organizational control below and by A4 - it is an accepted exception, not a
fail-closed guarantee. The organizational control: the only other
credentialed writer on this backend is the approving maintainer, and approval
of this plan includes not writing to `release-line:17.1.0` during the
announced execution window. A second credential provisioned mid-window would
defeat this; do not provision one.

## Preconditions (verify all, in this order, on the day)

| #   | Precondition                                      | Verify with                                                                                                                                                                                                                                                                                        |
| --- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| P1  | Fresh shell, no legacy selectors                  | `unset AGENT_COORD_BACKEND AGENT_COORD_REF AGENT_COORD_STATE_ROOT AGENT_COORD_STATUS_STATE_ROOT`, then `set -a; . ~/.config/agent-coord/env; set +a`                                                                                                                                               |
| P2  | Coordination backend reachable                    | `agent-coord doctor --json`: backend `http`, status `ok` (lightweight probe per AGENTS.md; `--deep` is for audit sweeps, not preflight)                                                                                                                                                            |
| P3  | `release/17.1.0` tip is the intended head         | `git ls-remote origin release/17.1.0` = `0f405eeef...` (re-pin on approval day if the branch moved; any move re-runs CI and the gate)                                                                                                                                                              |
| P4  | CHANGELOG stamped `### [17.1.0.rc.0]` at that tip | `git show origin/release/17.1.0:CHANGELOG.md \| grep -m1 '### \[17.1.0.rc.0\]'`                                                                                                                                                                                                                    |
| P5  | Full CI green on the exact tip                    | `gh run list --branch release/17.1.0 --json headSha,conclusion` - all workflows `success` on the tip SHA                                                                                                                                                                                           |
| P6  | ShakaPerf evidence and tracker exported           | `export RELEASE_SHAKAPERF_RUN=32630294983 RELEASE_TRACKER=4842` (the run selector aborts without `RELEASE_TRACKER`; verified in `release.rake`)                                                                                                                                                    |
| P7  | Publish ownership on all six packages             | `pnpm owner ls <pkg>` x4 contains `sasha_shakacode`; `gem owner <gem>` x2 contains `sasha@shakacode.com`                                                                                                                                                                                           |
| P8  | Local registry auth                               | `npm whoami` = `sasha_shakacode` (no pnpm equivalent exists; this is the one npm-CLI exception); RubyGems key in `~/.local/share/gem/credentials` with `push_rubygem`                                                                                                                              |
| P9  | Pre-run dist-tag snapshot                         | `for p in react-on-rails react-on-rails-pro react-on-rails-pro-node-renderer create-react-on-rails-app; do printf '%s %s\n' "$p" "$(pnpm view "$p" dist-tags.latest)"; done > /tmp/rc0-latest-before.txt` - one `<package> <version>` line each, the exact format the verification matrix consumes |
| P10 | Local/remote tag parity                           | `comm -23 <(git tag -l \| sort) <(git ls-remote --tags origin \| awk '{print $2}' \| sed 's\|refs/tags/\|\|;s\|\^{}$\|\|' \| sort -u)` prints nothing - W3 runs `git push --tags`, which pushes EVERY local-only tag, so parity confines it to exactly the release tag                             |
| P11 | Release-line lease held and live                  | runbook claim procedure (fresh UUID) + `require_live_release_line_lease` passes immediately before invocation                                                                                                                                                                                      |
| P12 | Watchdog loop running (dual renewal + kill)       | second shell: every 300s heartbeat, hourly claim renewal, and on any failure `kill -INT <rake pid>`; the rake PID is recorded the moment the task starts                                                                                                                                           |
| P13 | Dry run passes on the same head                   | `bundle exec rake "release[17.1.0.rc.0,true]"` completes with the expected file list                                                                                                                                                                                                               |

## The outward-write ledger

`rake release` performs, in order (anchored to `release.rake` as of
2026-08-23; re-anchor if the file changes):

| W   | Write                                                      | Where                                                               | Idempotent on re-run?                                                                                                                                                      |
| --- | ---------------------------------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| W1  | version-bump commit push to `release/17.1.0`               | `git push` (~10093)                                                 | yes - "No version changes to commit" path skips a done bump                                                                                                                |
| W2  | evidence comment on tracker issue #4842                    | `post_release_tracker_comment!` via the ShakaPerf gate verification | re-run posts a duplicate comment; harmless, note it in the announcement                                                                                                    |
| W3  | tag `v17.1.0.rc.0` push                                    | `git push --tags` (~5393), behind tag-authorization and guards      | guarded - a matching tag at head is retry-safe; a tag at the WRONG sha aborts (see A2). `--tags` pushes every local tag, so P10 parity is what confines W3 to this one tag |
| W4  | npm publish `react-on-rails@17.1.0-rc.0`                   | `publish_npm_with_retry`                                            | yes, once W3 exists (tag-at-head flips `idempotent_publish_retry`)                                                                                                         |
| W5  | npm publish `react-on-rails-pro@17.1.0-rc.0`               | same                                                                | same                                                                                                                                                                       |
| W6  | npm publish `react-on-rails-pro-node-renderer@17.1.0-rc.0` | same                                                                | same                                                                                                                                                                       |
| W7  | npm publish `create-react-on-rails-app@17.1.0-rc.0`        | same                                                                | same                                                                                                                                                                       |
| W8  | gem push `react_on_rails 17.1.0.rc.0`                      | `publish_gem_with_retry`                                            | same                                                                                                                                                                       |
| W9  | gem push `react_on_rails_pro 17.1.0.rc.0`                  | same                                                                | same                                                                                                                                                                       |
| W10 | GitHub release for `v17.1.0.rc.0` from CHANGELOG           | `sync_github_release_after_publish`                                 | yes - `rake "sync_github_release[17.1.0.rc.0]"` is standalone and documented for already-published versions                                                                |

Blast-radius note: the npm dist-tag for `17.1.0-rc.0` resolves to `rc`
(`npm_dist_tag_for_version`), so no rc publication moves `latest`. The gems
are prereleases; RubyGems does not surface them as the default version.

OTP model: one npm OTP is requested at the W4 boundary and reused across
W4-W7; the RubyGems OTP is prompted at the W8 boundary and reused for W8-W9,
with a replacement prompt if the TOTP window expires between gems. Every OTP
prompt, including a replacement, is a lease fence: re-verify before typing.
Auth failures abort; only OTP challenges and qualified transient network
errors retry.

## Reconciliation model

The task's own resume mode is the primary mechanism:
`idempotent_publish_retry` turns on when the release tag already exists on the
remote at the current head. Therefore:

- **Crash before W1:** nothing outward happened. Re-run.
- **After W1, before W3:** bump commit is on the branch; re-run detects it
  ("No version changes to commit"), re-validates gates, continues. A
  duplicate W2 tracker comment may appear; acceptable.
- **After W3, anywhere in W4-W9:** re-run from the same branch and head. The
  remote tag at head flips the run into idempotent retry mode: every
  already-published package answers "previously published" and is tolerated;
  missing ones are published. Do NOT hand-run `pnpm publish` or `gem push` to
  "finish" a partial state - always resume through the task so its guards and
  ordering apply.
- **After W9, before W10:** run `bundle exec rake "sync_github_release[17.1.0.rc.0]"`.
- **Verification failure after an apparently successful run:** treat as a
  mid-W4-W9 crash; resume through the task.

Re-run rule: the resume MUST use the same branch and a live lease (P11)
re-verified immediately before invocation. "Same head" changes meaning after
W1, so record two SHAs during the first attempt: `BASE_SHA` (the approved
pre-W1 tip that P3/P5 pinned and the ShakaPerf evidence binds to) and
`BUMP_SHA` (the tip immediately after W1). Resume-mode preconditions replace
P3/P5/P13:

- the branch tip equals `BUMP_SHA`, and
  `git diff --name-only BASE_SHA..BUMP_SHA` shows only version and lockfile
  files (the bump commit and nothing else); abort if anything more moved;
- CI and ShakaPerf evidence remain anchored to `BASE_SHA`: the release task's
  own non-runtime walk-back skips a version-only tip back to the last
  runtime-bearing commit, which is `BASE_SHA`, so no new CI run or evidence
  re-pin is required for the resume;
- the dry run (P13) is NOT re-run against `BUMP_SHA`; the original P13 result
  for `BASE_SHA` stands.

## Post-run verification matrix (hard assertions; all must pass before the lease is released)

```bash
set -e
V=17.1.0-rc.0; GV=17.1.0.rc.0
BUMP_SHA=$(git ls-remote origin refs/heads/release/17.1.0 | cut -f1); test -n "$BUMP_SHA"                  # W1
TAG_SHA=$(git ls-remote origin "refs/tags/v${GV}^{}" | cut -f1)
[ -n "$TAG_SHA" ] || TAG_SHA=$(git ls-remote origin "refs/tags/v${GV}" | cut -f1)
test "$TAG_SHA" = "$BUMP_SHA"                                                                             # W3: tag exists AND points at the bump sha
gh issue view 4842 --json comments --jq '.comments[-3:][].body' | grep -q "$GV"                           # W2: evidence comment present
for p in react-on-rails react-on-rails-pro react-on-rails-pro-node-renderer create-react-on-rails-app; do
  test "$(pnpm view "$p@$V" version)" = "$V"                                                              # W4-W7: published
  test "$(pnpm view "$p" dist-tags.rc)" = "$V"                                                            # rc tag moved to this version
  test "$(pnpm view "$p" dist-tags.latest)" = "$(grep "^$p " /tmp/rc0-latest-before.txt | cut -d' ' -f2)" # latest UNCHANGED vs P9 snapshot
done
curl -s https://rubygems.org/api/v1/versions/react_on_rails.json | jq -e "any(.[]; .number==\"$GV\")"     # W8
curl -s https://rubygems.org/api/v1/versions/react_on_rails_pro.json | jq -e "any(.[]; .number==\"$GV\")" # W9
gh release view "v$GV" --json isDraft,name --jq '.isDraft == false' | grep -q true                        # W10: exists and not draft
```

Only when all pass: release the claim (`agent-coord release ...`), then
announce (tracker #4842, Leslie, forward-port per runbook step 3).

## Abort conditions (stop, keep the lease, ping the maintainer; do not improvise)

- **A1:** any npm/gem rejection matching the task's registry-rejection
  patterns (`EPUBLISHCONFLICT`/`E403`/"cannot publish over"/"forbidden") that
  is NOT the idempotent already-published case.
- **A2:** the tag guard reports `v17.1.0.rc.0` existing at a DIFFERENT sha
  than the candidate. Never delete or move a pushed tag.
- **A3:** `require_live_release_line_lease` fails at any fence (pre-invocation
  or either OTP boundary) and one heartbeat refresh does not restore it.
- **A4:** the watchdog itself dies or fails to deliver the kill while the
  task is past the last OTP boundary: let the task finish, treat the whole
  run as unverified, go straight to the verification matrix, and start no
  other release-line write. This is the one residual case the plan cannot
  fail-close; it is part of the approved exception.
- **A5:** any gate (CI status, ShakaPerf boundary, authorization digest)
  aborts inside the task. Overrides (`override_ci_status` etc.) are out of
  scope for this plan and require a separate maintainer decision.
- **A6:** anything not described in this document.

Rationale for keeping the lease on abort: a held lease is the only signal that
the line is mid-write; releasing it on a partial state invites a second writer
into exactly the situation the policy exists to prevent.

## Out of scope

Final `17.1.0` promotion (accepted-RC path), dist-tag corrections, yanking or
deprecating any published artifact, org/team changes, and every override flag.
Phase 2 - the repository-owned wrapper - should implement this document as
code, at which point this plan retires and the runbook's compound-writer
prohibition applies unmodified again.
