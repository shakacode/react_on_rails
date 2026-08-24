# Install and Release

We're releasing this as a unified release with 6 packages total. We keep the version numbers in sync across all packages using unified versioning.

This page covers the mechanical `rake release` steps: version bumps, package
publishing, tags, and GitHub releases. For the release-train branching model
that decides when to cut `release/X.Y.Z`, stabilize RCs, promote the last good
RC to final, and close out the release branch, see
[Release-Train Runbook](release-train-runbook.md). For RC hard-gate evidence and
behavioral release verification lanes, see [RC Testing Plan](rc-testing-plan.md)
and [Release Verification Runbook](release-verification-runbook.md).

> **Execution boundary:** Live publication and accelerated-RC reconciliation use
> only `script/release VERSION` (or
> `script/release --reconcile-accelerated-rc VERSION`). The supervisor requires an already-active matching
> `release-line:X.Y.Z` claim under a fresh process UUID, maintains its heartbeat,
> and proves that each outward write still has the same live claim. It does not
> claim, take over, or automatically release the lease. Direct live
> `bundle exec rake release[...]` is refused; use Rake directly only with `dry_run=true`.
> For claim acquisition, identity variables, handoff, and partial-publication
> recovery, follow the [Release-Train
> Runbook](release-train-runbook.md#serialize-every-release-line-write).

The lease branch must equal the checkout used for publication. The runbook bootstrap defaults
`RELEASE_BRANCH` to the matching `release/X.Y.Z` train branch. For the documented ordinary stable
release from `main`, start a fresh coordinator shell with `RELEASE_BRANCH_INPUT=main`; prereleases and
accelerated-RC reconciliation remain restricted to the matching release branch.

## Testing the Gem before Release from a Rails App

See [Contributing](https://github.com/shakacode/react_on_rails/blob/main/CONTRIBUTING.md)

## Release Process

### Version ownership

The release task owns React on Rails' coordinated product-version changes. Release-preparation PRs
should update and stamp `CHANGELOG.md`, but should not manually bump React on Rails' own OSS/Pro gem
or npm version fields or create the ordinary `Bump version to ...` commit. `bundle exec rake
release[...]` updates the OSS and Pro gem version files, the `version` field in all five `package.json`
files, and the Ruby `Gemfile.lock` files in that generated commit. It does not run `pnpm install` or
regenerate `pnpm-lock.yaml`; workspace-protocol dependency conversion during npm publishing is
temporary and is restored afterward.

If a release-preparation or dependency-pin PR changes dependency ranges or pins, regenerate the
affected npm/pnpm lockfiles in that PR. Do not defer those lockfile updates to the React on Rails
product-version release task.

An independently published dependency pin is different: for example, moving from a
`react-on-rails-rsc` RC to its accepted stable version must be reviewed and tested before the next
React on Rails RC. Follow the ordered dependency-promotion gate in the
[Release-Train Runbook](release-train-runbook.md#promote-prerelease-dependencies-before-final).

### 1. Update the Changelog (BEFORE releasing)

**Always update CHANGELOG.md before running the release task.** The release task reads the version from CHANGELOG.md and automatically creates a GitHub release from the changelog section.

1. Ensure all desired changes are merged to `main` branch
2. Run the installed/shared `$update-changelog release` for ordinary mainline
   releases, or `$react-on-rails-update-changelog release`/`rc`/`beta` when the
   PR must target `release/X.Y.Z`, to:
   - Find merged PRs missing from the changelog
   - Add changelog entries under the appropriate category headings
   - Auto-compute the next version based on changes (breaking -> major, features -> minor, fixes -> patch) — skipped when an explicit version is provided
   - Stamp the version header (e.g., `### [16.5.0] - 2026-03-08`)
   - For `release`: collapse prior `rc`/`beta` sections of the same base version into the new stable section and deduplicate entries (`rc`/`beta` modes leave prior prerelease sections in place so users on an earlier RC can see what changed between RCs)
   - **Automatically commit, push, and open a PR** with the changelog changes
3. For minor and major releases, add a commit to the changelog PR updating `SECURITY.md`:
   - "Current support window" table so supported version lines and cutoff dates match the release being shipped
   - "Last reviewed" date and, when applicable, "Next review due"
4. Review the PR, verify the computed version, and merge

If a stable target lacks this section, the release task aborts before confirmation, tagging, or publication.
For a prerelease, the task warns and skips the GitHub release. After adding the section, preview the idempotent update
with the dry-run form `sync_github_release[X.Y.Z,true]`; for a live recovery, use the exact version through
`script/release VERSION` as documented in [Partial-publication recovery](release-train-runbook.md#partial-publication-recovery).

#### Why changelog comes BEFORE the release

- `rake release` automatically creates a GitHub release if a changelog section exists -- no separate `sync_github_release` step needed
- Before confirmation, the release task prepares the GitHub body and verifies it fits GitHub's limit. For unusually
  large sections, it first replaces repeated same-repository PR/issue URLs and contributor profile URLs with compact
  GitHub-native references without dropping entries. If the result is still too large, it keeps Markdown-safe beginning
  and ending excerpts and links to the complete tag-pinned changelog.
- The release task aborts a stable target if no matching non-empty section exists; prereleases warn and
  skip GitHub release creation
- A premature version header (if release fails) is harmless -- you'll release eventually
- A prerelease or historical release missing its changelog requires manual GitHub release synchronization

### 2. Preview the Release Task

The task reads the version from CHANGELOG.md when the version argument is empty. Preview that path,
or an explicit target, with `dry_run=true`:

```bash
# Reads version from CHANGELOG.md (requires step 1)
bundle exec rake "release[,true]"

# For a specific version (overrides CHANGELOG.md detection)
bundle exec rake "release[16.2.0,true]"

# For a pre-release version (note: use period, not dash)
bundle exec rake "release[16.2.0.beta.1,true]"  # Previews npm package 16.2.0-beta.1

# For a release candidate
bundle exec rake "release[16.5.0.rc.0,true]"

# Dry run to test without publishing
bundle exec rake "release[16.2.0,true]"

# Override version policy checks (monotonic + changelog/bump consistency)
RELEASE_VERSION_POLICY_OVERRIDE=true bundle exec rake "release[16.2.0,true]"
bundle exec rake "release[16.2.0,true,true]"
```

> **Retry safety:** Never drop the version argument when resuming an interrupted release. Retry the
> exact prerelease version; preview it with `bundle exec rake "release[17.0.0.rc.10,true]"`, then use
> the recovery procedure in
> [Partial-publication recovery](release-train-runbook.md#partial-publication-recovery). Live retry is
> only `script/release 17.0.0.rc.10` after its existing matching claim and exact evidence are verified. From a prerelease
> checkout, an argument-less release fails closed unless the changelog advances the same release line
> to a newer prerelease. Stable promotion must use an explicit stable version and a matching non-empty
> changelog section.

When called with no arguments, `rake release`:

1. Reads the first versioned header from CHANGELOG.md (e.g., `### [16.5.0]`)
2. Compares it to the current gem version
3. If the changelog version is newer, prompts for confirmation and uses it
4. If no new version is found from an already-stable checkout, derives a patch candidate; the stable
   changelog gate still blocks release until that version has a matching non-empty section. From a
   prerelease checkout, aborts with exact retry and stable-promotion guidance

Dry runs use a temporary git worktree so version bumps and installs do not modify your current checkout.

Both live releases and dry runs first verify npm publication readiness in the original checkout, immediately after
the clean-worktree check and verbosity setup. The root
`packageManager` must pin an exact pnpm version, the installed pnpm must match it, `node_modules/.pnpm/lock.yaml`
must byte-match the committed `pnpm-lock.yaml`, and every npm release package must pass its normal `build` script
with lifecycle scripts enabled. This happens before release-checkout creation, `git pull`, npm or GitHub
authentication, CI/tag/version-policy remote reads, registry probes, confirmation, version mutation, ShakaPerf
dispatch, tagging, publication, or OTP prompting. A pnpm version mismatch must first be repaired by activating the
exact pnpm version declared by the root `packageManager`. The release prints this frozen-install command for the
installed-dependency repair:

```bash
pnpm install --frozen-lockfile
```

After the initial check succeeds, the task binds it to the exact current commit. A live release then runs
`git pull --rebase` and immediately resolves `HEAD` again. If the pull advanced the checkout, all four release-package
builds and the rest of npm readiness run again in the live release root; `HEAD` is resolved once more after that check
so a concurrent commit change fails closed. Version resolution, authentication, CI, registry probes, confirmation,
and mutation remain unreachable until readiness is bound to the current release SHA. An unchanged live checkout runs
one readiness check, and a dry run neither pulls nor repeats the original-workspace check. Any missing or malformed SHA
resolution is a hard failure.

`rake release` validates release-version policy before publishing:

- Target version must be greater than the latest tagged release.
- If the versioned target changelog section exists (`### [X.Y.Z...]`; not `Unreleased`), it maps to expected bump type:
  - Breaking changes => major bump
  - Added/New Features/Features/Enhancements => minor bump
  - Fixed/Fixes/Bug Fixes/Security/Improved/Deprecated => patch bump
  - Other headings => no inferred bump level (consistency check is skipped)

Use override only when needed:

- `RELEASE_VERSION_POLICY_OVERRIDE=true`
- Or task arg override (`bundle exec rake "release[..., ..., true]"`)

**Full argument list:**

```bash
bundle exec rake "release[version,dry_run,override_version_policy,override_ci_status]"
```

1. **`version`** (optional): Version bump type or explicit version
   - Bump types: `patch`, `minor`, `major`
   - Explicit: `16.2.0`
   - Pre-release: `16.2.0.beta.1` (rubygem format with dots, converted to `16.2.0-beta.1` for NPM)
   - Empty (auto): use a newer changelog prerelease on the same release line; from an already-stable
     checkout, use a newer changelog version or derive a patch candidate that the stable changelog gate
     blocks until a matching non-empty section exists; otherwise abort with explicit retry guidance

2. **`dry_run`** (optional): `true` to preview changes without releasing (default: `false`)

3. **`override_version_policy`** (optional): `true` to override version policy checks (default: `false`)

4. **`override_ci_status`** (optional): global release-gate override (default: `false`). It is only for
   an explicitly approved prerelease waiver under the active RC policy; never use it for a stable/final
   promotion.

> Stable/final promotion must not set `RELEASE_CI_STATUS_OVERRIDE=true`, pass
> `override_ci_status=true`, or use an accelerated asynchronous/deferred-gate bypass. Every unwaived
> final gate must pass. A narrowly scoped final waiver remains subject to the existing final-release
> policy, required evidence, and maintainer sign-off, and does not waive any other gate.

**Environment variables:**

```bash
VERBOSE=1                    # Enable verbose logging (shows all output)
NPM_OTP=<code>               # Provide NPM one-time password (reused for all NPM publishes)
RUBYGEMS_OTP=<code>          # Provide RubyGems one-time password (reused for both gems)
RELEASE_VERSION_POLICY_OVERRIDE=true # Override release version policy checks
RELEASE_CI_EVALUATE_HEAD=true # Strictly evaluate the fetched exact release-source HEAD; not a waiver
RELEASE_CI_STATUS_OVERRIDE=true # DANGEROUS last-resort waiver for the release CI-status gate
RELEASE_ACCELERATED_RC=true # Explicit RC only: publish while named pending gates finish
RELEASE_TRACKER=<issue> # Active release tracker for ShakaPerf evidence, accelerated RCs, and final promotion
RELEASE_SHAKAPERF_RUN=<id-or-canonical-url> # Verify and durably associate one existing ShakaPerf run
RELEASE_FINAL_SHAKAPERF_WAIVER_REASON=<single-line-reason> # Stable-only observation-failure waiver
RELEASE_ACCELERATED_RC_REASON=<reason> # Single-line maintainer reason for accelerated publication
GEM_RELEASE_MAX_RETRIES=<n>  # Positive base-10 integer max retry attempts (default: 3)
```

#### Saving and reusing ShakaPerf release evidence

Use the open issue whose exact title is `Release gate: react_on_rails X.Y.Z` as the durable store. `X.Y.Z`
is always the stable base, so an RC such as `17.0.1.rc.3` is bound to `Release gate: react_on_rails 17.0.1`.
Release-related labels are advisory and cannot substitute for the exact title. The selected tracker and every
tracker reached by repository-wide durable-history discovery must satisfy this same target binding. To associate
a run that was started manually or missed by automatic discovery, provide the same active tracker used by the
release train and either the numeric run ID or its canonical GitHub URL:

```bash
RELEASE_TRACKER=4806 \
RELEASE_SHAKAPERF_RUN=https://github.com/shakacode/react_on_rails/actions/runs/30417447319 \
bundle exec rake "release[17.0.1,true]"
```

This preview validates the target and tracker inputs but does not fetch or persist the selected run. Live
association uses the repository-owned `script/release VERSION` wrapper described in the execution boundary.

This selector is not a waiver. Before appending anything, the task fetches the run and its schema-v2
artifact from GitHub and verifies repository, workflow, branch, target version, run ID and attempt,
terminal success, completion time, candidate SHA, evidence digest, and runtime fingerprint. The tracker
comment is append-only, attributed to a repository maintainer, and re-fetched before the task continues.
Saving the same association again is idempotent.

An explicit `RELEASE_SHAKAPERF_RUN` is authoritative for selection, not a hint. During stable promotion it
bypasses automatic accepted-RC ShakaPerf reuse and goes directly through strict-final selector verification and
persistence. It cannot be combined with `RELEASE_ACCELERATED_RC=true`. It also cannot be supplied on an unflagged
same-candidate retry once durable discovery proves that the retry is accelerated; this aborts before approver,
CI, mutation, or evidence-refresh work.

The trusted canonical tracker comment is the durable source of truth. A local
`shakaperf-release-evidence.json` is only a downloaded artifact/cache used during verification; it is never
the durable source of truth and cannot authorize reuse by itself.

On a later invocation, set `RELEASE_TRACKER` without `RELEASE_SHAKAPERF_RUN`. The task reads trusted,
unedited machine comments, re-fetches the saved run and artifact, and re-runs the same checks. Exact-SHA
evidence is preferred. Existing machine-verified runtime-equivalence remains supported because the stored
candidate is bound to the live run while the schema-v2 runtime fingerprint is compared with the current
release commit. Output names both the tracker URL and reused run URL. Candidate history is always read through the
authoritative repository issue-comments endpoint, bounded from one second before the candidate commit timestamp.
When `RELEASE_TRACKER=<issue>` is present, that issue is the expected canonical tracker, but the repository-wide read
still proves that no conflicting tracker contains a matching candidate record. For a known-tracker recovery, use the
fenced invocation:

```bash
RELEASE_TRACKER=<issue> script/release VERSION
```

The repository-wide candidate-bounded read applies with or without `RELEASE_TRACKER`. It fails closed as `UNKNOWN` at
the configured page or marker bound, or when the candidate commit timestamp cannot be established.

Only automatic association reuse may discard naturally invalid evidence and continue through normal discovery.
That recovery is limited to authoritative staleness, a 404-proven missing run or artifact, GitHub CLI's exact
`no valid artifacts found to download` diagnostic, a live run now completed with `failure` or `cancelled`, or proof
that the current runtime tree, intervening commits, or ancestry is no longer equivalent. The artifact diagnostic is
matched case-insensitively; authentication, permission, rate-limit, server, DNS, and timeout errors remain unknown
observation failures rather than absence. A Git `merge-base --is-ancestor` exit 1 is authoritative non-ancestry.
Failures or malformed results from
`git ls-tree`, `merge-base`, `rev-list`, `diff-tree`, or `script/ci-changes-detector` are unknown and block without
dispatching a replacement run. Explicit selectors reject both authoritative invalidation and unknown verification.
Edited, malformed, unsupported, or noncanonical trusted
comments; author/tracker/title mismatch; conflicting latest records; record/live identity conflict; digest or
fingerprint mutation; artifact parse or shape errors; and authentication, permission, pagination, parse, or other
indeterminate API failures all remain hard failures. Absence must therefore be proved, never inferred from an
unknown observation.

Inspect the durable state with `gh issue view 4806 --repo shakacode/react_on_rails --comments`. To replace
an association, run the explicit selector again with a newer verified run; the newest trusted association
for that exact candidate becomes the default. Use `RELEASE_SHAKAPERF_RUN` to choose between equally timed
conflicting records. Machine comments must not be edited or deleted: an edited trusted record fails closed.
To stop using saved evidence without mutating the audit trail, omit `RELEASE_TRACKER`; normal discovery then
applies and dispatches a fresh exact-head run when no reusable evidence exists.

If GitHub observation fails after an exact run has been identified, a maintainer may use the narrowly scoped
stable-only escape hatch:

```bash
RELEASE_TRACKER=4806 \
RELEASE_FINAL_SHAKAPERF_WAIVER_REASON="GitHub REST observer exhausted its quota" \
script/release 17.0.1
```

The task writes and re-fetches an append-only schema-v2 `gate_observation_failed` waiver bound to the exact tracker,
repository, canonical workflow, `workflow_dispatch` event, branch, stable version, candidate SHA, run ID, positive
run attempt, URL, reason, and authenticated maintainer. Canonical schema-v1 waiver markers remain readable,
approver/tracker-bound audit history, but they are deliberately non-authorizing; a new schema-v2 record must be
appended for the candidate. Malformed, edited, or noncanonical legacy markers still fail closed. The waiver
preserves the last observed run status and conclusion and never reports the run as successful. The waiver
cannot apply to prereleases, a failed/cancelled or otherwise terminal run, malformed/mismatched/stale
evidence, a rerun attempt, or a different current run/reason. It waives only inability to observe ShakaPerf; CI, version
policy, tag, registry, accepted-RC, and publication-boundary checks remain unchanged and blocking.
Immediately before the remote tag push and again before package publication, the task revalidates that the
tracker is still canonical and active, the append-only waiver and its exact attempt are unchanged, and the exact run
identity and attempt are still active. Continued API unavailability remains covered by the recorded observation
waiver, but a terminal, rerun, wrong-identity, or
unknown run state, a closed/noncanonical tracker, or a changed/disappeared waiver blocks publication.

#### Release CI evidence and strict HEAD evaluation

For this gate, **HEAD** means the fetched exact tip of the release-source branch that would be
tagged and published: `origin/main` for a mainline release or `origin/release/X.Y.Z` for a
release-branch cut/promotion. It never means an unpushed local checkout tip.

Normally, the gate walks back metadata-only commits (for example, a changelog/version commit) to
the newest runtime-bearing commit. This is intentional: CI path filtering can attach no meaningful
runtime suite to metadata-only commits, while the runtime-bearing commit is the one whose full
suite establishes release health.

`RELEASE_CI_EVALUATE_HEAD=true` disables only that walkback. It still queries and enforces the
same CI gate at the exact fetched HEAD; it is a strict evaluation, not a waiver. It is appropriate
only for the narrow topology where GitHub attached complete workflows to the final release tip,
while the intermediate runtime SHA selected by normal walkback has zero usable runs.

| Normal walkback / exact HEAD evidence                                                                                      | Required action                                                                                            |
| -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Walked-back SHA has usable CI evidence                                                                                     | Let the normal gate decide. Do not set either variable.                                                    |
| Walked-back SHA has no usable runs; exact HEAD is pending                                                                  | Wait for the linked exact-HEAD checks. They remain blocking.                                               |
| Walked-back SHA has no usable runs; exact HEAD has failed checks                                                           | Fix or otherwise resolve the failures. They remain blocking.                                               |
| Walked-back SHA has no usable runs; exact HEAD is completely healthy under the same stable/prerelease required-check rules | Re-run with `RELEASE_CI_EVALUATE_HEAD=true`; it evaluates that exact HEAD and still blocks on any failure. |
| Walked-back SHA has no usable runs; exact HEAD has no checks, unknown status, or an API failure                            | Fail closed. Wait for evidence or repair API/auth access; do not use strict HEAD without evidence.         |
| Any case where a maintainer-approved waiver is truly required                                                              | `RELEASE_CI_STATUS_OVERRIDE=true` is the dangerous last resort, not a recovery default.                    |

Examples:

```bash
# Only after the task reports complete healthy exact-HEAD evidence, retry the explicit target version:
RELEASE_CI_EVALUATE_HEAD=true bundle exec rake "release[17.0.0.rc.10,true]"
```

Do not use `RELEASE_CI_STATUS_OVERRIDE=true` to substitute for pending, missing, failed, or
unknown exact-HEAD evidence. It waives the release CI-status gate and does not make CI healthy.

#### Audited accelerated RC publication

The accelerated path exists only to start published-artifact testing of an explicit RC while
otherwise healthy exact-head CI or ShakaPerf is still pending. It is not a waiver and does not
apply to beta/alpha versions or stable/final releases. Use it only with an active release tracker
and a GitHub account that has write, maintain, or admin permission:

```bash
RELEASE_ACCELERATED_RC=true \
RELEASE_TRACKER=4821 \
RELEASE_ACCELERATED_RC_REASON="Start published-artifact fleet testing while the named gates finish" \
bundle exec rake "release[17.0.0.rc.10,true]"
```

Accelerated publication and same-candidate durable retries must run from the exact matching
`release/X.Y.Z` branch for the RC target. Before accelerated mode is known, the generic prerelease retry check may
inspect or fetch exact-target tag state. Same-candidate durable retry resolution may also perform bounded, read-only
repository-history discovery, author-permission checks, and tracker-eligibility reads before it can establish that
accelerated options exist. Once options resolve, the branch guard runs before explicit accelerated target-tag
preflight, post-resolution selected-tracker and approver access, CI confirmation, version mutation, push, workflow
dispatch, tracker mutation, tag handling, or publication. Ordinary non-accelerated prereleases may still be cut from
non-release feature branches.

The task rejects the accelerated path when the version is implicit, the target is not a canonical
lowercase `.rc.` version, the tracker is closed or ineligible, the reason is missing, or
`RELEASE_CI_STATUS_OVERRIDE` or `RELEASE_SHAKAPERF_RUN` is also set. The selector incompatibility also applies
after an unflagged same-candidate retry discovers persisted accelerated options. Case-varied spellings such as `.RC.` are rejected before
tracker records or tag provenance can be created. Every numeric core component and the numeric `rc`
identifier must also use canonical npm-semver spelling: zero itself is valid, but leading zeroes are not.
It still fails closed on failed, missing, malformed,
ambiguous, stale, or API-unknown evidence. The only release-source CI state it may defer is a visible
in-progress state.

After pushing the version-bump commit, the task binds all evidence to that exact SHA. It reuses a
verified ShakaPerf run or dispatches one and records its URL without waiting for completion, then
queries exact-head CI and displays every non-success check and URL. A second confirmation names the
RC, exact SHA, tracker, ShakaPerf run, pending CI checks, and maintainer reason before any tag or
package is published. Immediately after that answer, the task refreshes both exact-candidate CI and the
recorded ShakaPerf run. Failure, missing or malformed evidence, an unknown API result, or an unrecognized
state aborts before authorization is recorded. If refreshed evidence is still deferable but materially
differs from what the prompt displayed, the task displays the new snapshot and requires confirmation again;
continually changing evidence eventually aborts rather than authorizing an unstable snapshot. It then
appends the refreshed machine-readable `publication-authorized` record before
creating the tag or publishing any package. After all six immutable npm and RubyGem artifacts are
confirmed, it immediately appends `published-awaiting-gates` before fallible GitHub-release synchronization
or other post-publish work. Partial package publication never appends that transition; once every package
is published, a later GitHub-release sync failure still leaves the candidate durably awaiting reconciliation.
At that completion boundary, the task first proves that the selected tracker is still eligible and that bounded,
authoritative repository comment history from the candidate commit forward has one canonical authorization with no
absorbing rejection. It repeats that proof after append or idempotent reuse and rejects matching records on any other
tracker. GitHub issue search is eventually indexed and therefore is never used as the completeness oracle.
If all six artifacts became public but that completion append was interrupted, the reconciliation task can
recover the missing transition before it evaluates the deferred gates. Recovery requires the canonical
authorization-only selected-tracker history, the exact remote annotated RC tag object, its peeled candidate SHA and
authorization provenance, and exact registry metadata for all four npm packages and both RubyGems. It
revalidates the complete remote tag-object/candidate identity after the registry reads and then uses the normal
selected-tracker completion append. Partial, mismatched, malformed, ambiguous,
or unavailable registry/tag/history evidence blocks, and a GitHub outage still blocks durable recovery; there
is no offline or unaudited completion bypass.
Retries reuse the same candidate without appending duplicate status records. Accelerated RCs use an annotated
tag containing canonical tracker and
authorization provenance; retries load and reuse that persisted authorization instead of refreshing
it into a conflicting record. Persisted authorization is not permission to reuse stale pending evidence:
before retrying any tag or immutable publication, the task refreshes exact-candidate CI and the exact
recorded ShakaPerf run. Current success remains usable, and only a live in-progress state with no
conclusion that is bound to the immutable RC candidate may remain deferred. A different-SHA pre-run must
already be completed successfully and pass the live artifact, runtime-tree, ancestry, and metadata-only
commit proof; an active different-SHA run cannot be authorized, persisted, reused, or carried across a
publication boundary. An active status paired with any non-null conclusion is contradictory evidence and
blocks. Failed, missing, malformed, stale, API-unknown, or otherwise non-deferable evidence also blocks the
retry. Every same-version-and-SHA retry discovers durable history first. When `RELEASE_TRACKER` is supplied,
it identifies the expected canonical issue while authoritative repository issue-comment enumeration still checks the
candidate across trackers. Its canonical authorization chain controls the retry, and explicit tracker, reason, and options must match that
authorization exactly, and a rejected or conflicting chain remains blocking. The task never refreshes or
creates a conflicting authorization. A history-free explicit attempt may create its first authorization only
when the exact RC tag does not exist. An existing ordinary lightweight RC tag can be retried unflagged through
the ordinary path, but `RELEASE_ACCELERATED_RC=true` cannot convert it or append accelerated history that lacks
matching annotated-tag provenance. Every explicit accelerated cut checks both the local and `origin` exact-target
tag and force-fetches a remote-only tag for provenance classification, regardless of the starting checkout
version. An unavailable remote read or unclassifiable tag blocks. This runs before live gates, confirmation,
version mutation, tracker append, or push; only an exact canonical annotated retry from its tagged candidate
may continue.
Exact-head CI snapshots sort non-success checks canonically by name, state, and URL before persistence and
comparison. API enumeration-order changes therefore do not require another confirmation or block a publication
boundary, while any real check identity, state, URL, duplicate, or conflicting-entry change remains material.
Before accepting, reusing, or appending that authorization, the task loads trusted repository issue comments updated
since the candidate commit for the exact version and SHA and requires one canonical chain on the expected tracker. It
repeats that repository-wide proof after posting and immediately before tag handling. Candidate commit time in the
future, history recorded before that commit, malformed chronology, or a bounded page/marker limit blocks. Before tag
handling, immediately
before tag push, and again after tag push before package publication, accelerated RCs also refresh exact-head
CI and the recorded ShakaPerf run. A newly failed, missing, malformed, or unknown gate blocks; pending evidence
must still exactly match the confirmed authorization, and pending ShakaPerf must name the immutable RC candidate,
while a transition to success is allowed. A material
pending-state change is untriaged at these boundaries and requires a new authorization rather than silent reuse.
Omission never downgrades an interrupted accelerated attempt to an ordinary lightweight-tag release and
never permits the broad prerelease CI override. A genuinely ordinary RC with no accelerated history keeps
its lightweight-tag path. Before a fresh exact-head asynchronous ShakaPerf dispatch, a latest structurally valid
same-target pre-run with a completed known failure or unknown terminal conclusion blocks publication instead of being
superseded by new pending evidence. Accelerated selection first classifies every fetched run as the exact target, a
canonically self-consistent unrelated target, or unknown; only proven unrelated evidence is ignored. Missing, malformed,
or mismatched title, head, run, attempt, URL, status, conclusion, or timestamp identity remains visible and cannot
authorize reuse. Before target filtering, duplicate collapse, ordering, reuse, or dispatch, every fetched accelerated
run—including a canonically unrelated target—must have positive integer run and attempt IDs and the literal URL
`https://github.com/<bound-repository>/actions/runs/<same-run-id>` with no alternate host, repository, path, port, query,
fragment, or normalization. The API state is also total: active states permit only a null conclusion, completed runs
require a recognized terminal conclusion, `createdAt` and `updatedAt` must be present and ordered parseable timestamps,
and every state except queued requires a present `startedAt` ordered between them. A queued run may have a null
`startedAt`; a non-null value must still be parseable and ordered. The same contract applies to a freshly dispatched run
and every later refresh. During accelerated post-dispatch polling, the complete fetched array and every member are
validated before target, ignored-run, or dispatch-time filtering; conflicting duplicates, ambiguous multiple fresh runs,
and any malformed or unknown sibling block independent of API order. Only a fully valid canonical unrelated run is
ignored. Accelerated evidence never synthesizes a missing run URL. A valid active exact-head run may remain pending and
a valid active pre-run may trigger an exact-head dispatch during fresh selection, but that active different-SHA run is
never itself persisted or reused as deferred evidence. Malformed or contradictory evidence blocks before either
disposition. The selected exact-head or pre-run state is classified before a dispatch request can take effect, so any
selected known failure or unknown state outranks pending dispatch independent of API order. This accelerated-only polling
seam does not change the ordinary blocking ShakaPerf waiter or its historical display-URL fallback.
Conflicting duplicate run identities or equal ordering keys block independent of API order; only canonically identical
duplicates collapse. A deterministically newer ordered success may supersede older ordered failures after normal
runtime-equivalent evidence verification, while a newer ordered failure remains blocking. Reusable successful pre-runs
remain valid, and only fully formed canonically unrelated targets are ignored without poisoning the lane. Same-version
retry discovery must complete successfully before the task can
prove that accelerated history is absent; API, pagination, permission, or parse failure therefore blocks
that retry as unknown. Repository and selected-tracker discovery read chronological 100-comment pages
incrementally, validate string bodies, positive unique comment IDs, canonical repository issue URLs, parseable string
creation and update timestamps, and nondecreasing creation times, and retain only comments containing the explicit hidden
machine-marker opener
with the literal ASCII opener `<!-- react-on-rails-accelerated-rc `, including its single trailing space. A plain-text
mention, suffix lookalike, alternate whitespace, or escaped opener is ordinary discussion: it is not parsed, attributed,
or counted toward the marker bound. Exactly 1,000 retained machine-marker comments are allowed, and a short 250th page
completes discovery; exceeding 1,000 markers or requiring a 251st page blocks as unknown instead of ignoring history or
exhausting unbounded memory/API work. Missing, malformed, or unparseable creation or update timestamps block even on
markerless API comments. Durable marker comments must remain unedited: their parsed creation and update instants must be
equal, so an in-place rewrite of acceptance, rejection, conflict, approval, or evidence fields blocks before trust or
state use. A safely structured markerless ordinary comment may remain ignorable when its author envelope is exactly
`user: nil`. An explicit machine-marker comment with `user: nil` instead blocks replay as unattributable history, because
silently dropping it could erase an absorbing rejection or another durable transition. A missing or malformed author
envelope is likewise unknown and blocks. Unattributable machine-marker comments cannot authorize, satisfy, mutate,
conflict with, or be omitted from trusted history. A marker comment is ignored before author permission checks only when it contains
exactly one canonical marker whose payload is the byte-for-byte lowercase hexadecimal encoding of key-sorted
canonical JSON for a complete, structurally valid tracker record and proves it targets another
version-and-SHA pair. Reordered or whitespace-varied JSON, uppercase hexadecimal, incomplete records,
unknown fields, noncanonical state, odd-length or partially decoded payloads, escaped or corrupt identities,
malformed boundaries, duplicated markers, and
spoofed summaries cannot prove irrelevance and therefore reach strict parsing and block. Discovery comments
must name the canonical API issue URL in the exact requested repository; wrong hosts, repositories, paths,
queries, and fragments are rejected before their issue number is used. Every tracker referenced by a plausible
exact-candidate marker is fetched once and must be an open issue with the exact stable-base title derived from that
record's target version; labels do not substitute. This is the same eligibility check used by selected-tracker
publication. Pull requests cannot serve as release trackers even though GitHub exposes their comments through the
issues APIs.

ShakaPerf evidence is bound to the requested version, workflow run, run attempt, and candidate SHA
through reconciliation and every publication boundary. Reused accepted-RC evidence remains bound to
the accepted record's exact stored snapshot. That snapshot can identify a verified runtime-equivalent pre-run whose
candidate differs from the immutable RC candidate only after the run completed successfully and passed mechanical
verification; the pre-run policy is rechecked live, while accepted-RC and final-tip
runtime equivalence remain separate required gates. A newly run strict final gate is instead bound directly to the final
candidate. Every authorization record must have the
same canonical digest; canonical-digest-identical duplicates are idempotent, but any distinct
authorization blocks append, retry, reconciliation, and final promotion. Every
`published-awaiting-gates` record for the candidate must be the complete canonical transition from
that authorization. Only `approved_by` and `recorded_at` may differ across idempotent publication
completion retries; any other contradiction blocks append, retry, reconciliation, and final
promotion. An empty publication set is valid only before immutable publication. Reconciliation and
final promotion require at least one canonical `published-awaiting-gates` transition. Durable records must
be ordered authorization, publication completion, then terminal state, with parseable monotonic timestamps.
Exact authorization duplicates and the narrowly permitted publication/terminal retry variants remain
idempotent only within their phase; pending transitions after terminal state are invalid.
Reconciliation performs bounded authoritative repository exact-version-and-SHA validation against the canonical
authorization before reporting existing terminal state or appending a new terminal transition, then repeats
that validation after the append helper re-fetches durable history.

Reconcile the record after the deferred gates and all downstream RC testing finish. The live
reconciliation command is intentionally omitted here; run it only from the guarded release coordinator
flow in the [Release-Train Runbook](release-train-runbook.md#serialize-every-release-line-write).

Reconciliation refreshes exact-candidate CI and the recorded ShakaPerf run. A known failure writes
`candidate-rejected` with do-not-promote guidance; fix the cause and cut the next immutable RC.
Pending or unknown evidence remains unresolved and cannot be accepted. Success requires HTTPS links
for demo-fleet, behavioral, and published-artifact verification before the task writes
`candidate-accepted`. Terminal state is validated as a complete set: accepted duplicates are
idempotent only when every field except `recorded_at` is identical, and any other accepted-record
variation is conflicting. `candidate-rejected` is absorbing; append-time revalidation prevents a
concurrent reconciliation from adding acceptance or any other later transition. Every posted transition
is re-fetched and proven present in the complete canonical chain before the task proceeds toward immutable
publication or reports reconciliation success. Aside from the canonical unrelated-marker cheap skip above,
selected-tracker and repository-wide scans ignore an attributable marker comment based on its author only after GitHub
successfully proves that author lacks maintainer permission. Unattributable comments are never trusted evidence; an
unknown permission/API result for an attributable author, every malformed or unsupported record from a trusted author,
and any trusted record whose named approver does not match its comment author still fail closed. Only the explicit
`none`, `read`, or `triage` permission results count as a known non-maintainer classification;
blank, missing, malformed, unsupported, or future permission values are unknown and block even when the API call
itself succeeded. Status-specific
contradictions also fail closed: accepted records require every success and evidence URL, while
rejected records require a known failed gate.

Final promotion of an accelerated RC from `release/X.Y.Z` requires `RELEASE_TRACKER=<issue>`;
ordinary strictly gated lightweight RC tags keep the standard promotion path only when no tracker is
supplied and complete repository-wide exact-version-and-SHA discovery proves that no durable accelerated
history exists. Supplying `RELEASE_TRACKER` while the RC tag lacks canonical accelerated provenance, or
finding accelerated history behind a lightweight tag, blocks promotion instead of falling back to the
ordinary path. A markerless annotated RC
tag is never treated as ordinary, and inability to determine the tag object type blocks promotion as
unknown. For an accelerated RC, `RELEASE_TRACKER` must match the tracker encoded in the annotated RC
tag, the tag's authorization digest must match the canonical `publication-authorized` record, and the
candidate's latest state must be `candidate-accepted`. Missing or deleted authorization or publication
transition, mismatched trackers, and any `candidate-rejected` state block permanently. The accepted
record must bind to the exact remote RC tag SHA and be complete. A provenance-bearing accelerated tag must
also use the literal canonical ref `v<target_version>` with lowercase dotted `.rc.` spelling; a dashed or
case-varied alias is rejected even when it points at the same annotated object. Dashed-tag compatibility is
limited to ordinary RCs for which complete discovery proves there is no accelerated provenance or history.
Final promotion re-fetches the selected tracker's exact-version-and-SHA chain identified by the canonical tag
provenance. This selected-tracker read does not prove that another tracker has no matching record. The final tip
must be that SHA or
mechanically runtime-equivalent through the existing metadata-only promotion rules. Runtime
equivalence is checked again after the final version-bump commit. The task first proves that the immutable
accepted RC still exactly matches its recorded runtime fingerprint. When the final SHA differs, the canonical
positive-only commit classifier then decides the RC-to-final delta and must return canonical lowercase 40-hex commit
identities; a coarse final-tip fingerprint cannot override that classification or reject a positively classified
docs/comment-only delta. Every intervening commit is inspected:
package manifests, version files, and `Gemfile.lock` files may differ only by their normalized product-version
metadata, while dependency, lockfile, or any other runtime-bearing content change requires a new accepted RC
and cannot fall back to a fresh final ShakaPerf run. Accepted ShakaPerf evidence is
refreshed and re-verified against the final tip when automatic reuse applies. An explicit
`RELEASE_SHAKAPERF_RUN` instead bypasses that reuse and must pass and persist through the strict final selector
path; otherwise the normal strict final ShakaPerf gate runs only for a still-runtime-equivalent finalization.
After that gate completes, the task re-fetches the live
remote RC tag, selected-tracker canonical chain, and exact accepted-RC CI immediately before stable
tagging and publication. The re-fetched accepted record must differ from the originally gated record only by its
permitted retry timestamp. Local `HEAD` must still equal the validated final candidate, and the stable tag
is created and verified against that explicit SHA rather than implicit moving `HEAD`. Deletion, mutation,
newly appended rejection or conflict, or pending, failed, missing, stale, or unknown current evidence
blocks the boundary. Both `publication-authorized` and `published-awaiting-gates` are unresolved states
that block final promotion. Stable CI, version policy, and every other final gate remain strict. Multiple
remote tag names that normalize to the same RC version are ambiguous and block every first-promotion and
retry source-selection route, regardless of alias ordering or which alias carries accelerated provenance.
After existing-tag validation or explicit-SHA tag creation, the task revalidates both local `HEAD` and the
tag against the carried candidate SHA immediately before `git push --tags`. After the push it repeats the local
validation and resolves the live remote stable tag's peeled SHA immediately before package publication. Accelerated
final promotion additionally carries the canonical source RC tag, its exact annotated tag-object SHA, its peeled
candidate SHA, and its authorization provenance. At final tag handling, immediately before stable-tag push, and
after stable-tag push before packages, it requires the local ref and one live remote direct/peeled snapshot to match
that same captured object and candidate; deletion, movement, replacement by another same-candidate tag object or a
lightweight tag, lost provenance, or an unclassifiable tag blocks. This source-tag check is additional to the live
stable-tag peeled-SHA validation. For
accelerated RC publication and accelerated-RC
final promotion, both boundaries also re-fetch the selected tracker's trusted history for the exact RC candidate
and require the same canonical, retry-equivalent authorization/terminal chain. A new rejection, chain mutation,
missing record, or unknown selected-tracker read aborts before the
next irreversible step. Accelerated final promotion also carries the exact refreshed RC CI snapshot and the
exact ShakaPerf identity that passed the final gate, whether reused from the accepted RC or produced by a new
strict final run. The carried boundary context names that mode explicitly: reused evidence must exactly match the
accepted record's stored candidate, target, run, and attempt, including a validated pre-run candidate when applicable;
live refreshes compare that stored candidate with the accepted RC candidate so the pre-run policy remains required.
Strict-final evidence must match the validated final candidate and stable target. A strict-final run is also captured as
a frozen canonical identity anchor containing its
branch/ref, run ID, attempt, URL, candidate, target, and release-start identity. At publication-operation entry, the
task copies that validated anchor outside the mutable carried context; replacing both the live record and its context
anchor therefore cannot redefine the evidence that passed the gate. The complete context identity, including that mode
and candidate/target binding, is revalidated at tag handling, immediately before stable-tag push, and after the push
before packages. The task also
refreshes and compares the live gate evidence at each boundary; failed, missing, malformed, stale, unknown, or materially
changed evidence blocks. All of those exact-RC CI refreshes use the carried final-promotion branch, even when the accepted
RC record originated on a different source branch. A `candidate-accepted` stable-tag boundary without this complete,
internally consistent final-promotion context aborts before tag handling; nil context remains valid only for ordinary
releases and accelerated RC publication authorization, which use their separate live boundaries. Accelerated or broad
CI override flags cannot weaken final promotion.

**Examples:**

```bash
bundle exec rake "release[,true]"                         # Preview auto-detected version
bundle exec rake "release[patch,true]"                    # Preview patch bump (16.1.1 → 16.1.2)
bundle exec rake "release[minor,true]"                    # Preview minor bump (16.1.1 → 16.2.0)
bundle exec rake "release[major,true]"                    # Preview major bump (16.1.1 → 17.0.0)
bundle exec rake "release[16.2.0,true]"                   # Preview explicit version
bundle exec rake "release[16.2.0.beta.1,true]"            # Preview prerelease (→ 16.2.0-beta.1 for NPM)
VERBOSE=1 bundle exec rake "release[patch,true]"          # Preview with verbose logging
```

### 3. What the Release Task Does

The `rake release` task automatically:

1. **Validates release prerequisites**:
   - Checks for uncommitted changes (will abort if found)
   - Verifies NPM authentication (will run `npm login` if needed)
   - Verifies the exact pinned pnpm version, frozen installed lock state, and lifecycle-enabled builds for all npm
     release packages before registry checks or any release mutation
   - Requires a non-empty matching CHANGELOG.md section for stable targets; prereleases without one emit a warning,
     including during dry runs
   - Validates version policy (monotonic + changelog/bump consistency)
2. **Pulls latest changes** from the repository
3. **Bumps version numbers** in:
   - `react_on_rails/lib/react_on_rails/version.rb` (Ruby gem version)
   - All `package.json` files (npm package versions - converted from Ruby format)
   - Pro version files
4. **Updates Gemfile.lock files** across the monorepo
5. **Commits, tags, and pushes** all version changes
6. **Publishes to npm** (requires 2FA token):
   - `react-on-rails`
   - `react-on-rails-pro`
   - `react-on-rails-pro-node-renderer`
   - `create-react-on-rails-app`
7. **Publishes to RubyGems** (requires 2FA token):
   - `react_on_rails`
   - `react_on_rails_pro`
8. **Creates GitHub release** from CHANGELOG.md (if the matching section exists)

### What Gets Released

The release task publishes 6 packages with unified versioning:

**PUBLIC (npmjs.org + rubygems.org):**

1. **react-on-rails** - NPM package
2. **react-on-rails-pro** - NPM package
3. **react-on-rails-pro-node-renderer** - NPM package
4. **create-react-on-rails-app** - NPM package
5. **react_on_rails** - RubyGem
6. **react_on_rails_pro** - RubyGem

### Version Synchronization

The task updates versions in all the following files:

**Core package:**

- `react_on_rails/lib/react_on_rails/version.rb` (source of truth for all packages)
- `package.json` (root workspace)
- `packages/react-on-rails/package.json`
- `Gemfile.lock` (root)
- `react_on_rails/spec/dummy/Gemfile.lock`

**Pro package:**

- `react_on_rails_pro/lib/react_on_rails_pro/version.rb` (VERSION only, not PROTOCOL_VERSION)
- `packages/react-on-rails-pro/package.json` (+ dependency version)
- `packages/react-on-rails-pro-node-renderer/package.json`
- `packages/create-react-on-rails-app/package.json`
- `react_on_rails_pro/Gemfile.lock`
- `react_on_rails_pro/spec/dummy/Gemfile.lock`

**Note:**

- `react_on_rails_pro.gemspec` dynamically references `ReactOnRails::VERSION`
- `react-on-rails-pro` NPM dependency is pinned to exact version (e.g., `"react-on-rails": "16.2.0"`)

### 4. Version Format

**Important:** Use Ruby gem version format (no dashes) when passing versions to the rake task:

- Correct: `16.1.0`, `16.2.0.beta.1`, `16.0.0.rc.2`
- Wrong: `16.1.0-beta.1`, `16.0.0-rc.2`

The task automatically converts Ruby gem format to npm semver format:

- Ruby: `16.2.0.beta.1` -> npm: `16.2.0-beta.1`
- Ruby: `16.0.0.rc.2` -> npm: `16.0.0-rc.2`

**CHANGELOG.md headers** use RubyGems dot format (without `v` prefix):

- `### [16.5.0.rc.1]` -- correct (matches gem version format)

**CHANGELOG.md compare links** at the bottom of the file MUST use the `v` prefix to match git tags:

- `[16.5.0.rc.1]: https://github.com/shakacode/react_on_rails/compare/v16.4.0...v16.5.0.rc.1` -- correct

### 5. During the Release

1. When prompted for **npm OTP**, enter your 2FA code from your authenticator app
2. When prompted for **RubyGems OTP**, enter your 2FA code
3. Invoke the live release with an explicit version through `script/release VERSION`; direct live Rake is refused.
   A stable checkout may derive a patch candidate in a dry run, but publication still requires a matching non-empty
   changelog section.
4. The script will automatically commit and push version bumps
5. The script will automatically create a GitHub release (if CHANGELOG.md section exists)

### 6. After Release

1. Verify the release on:
   - [npm](https://www.npmjs.com/package/react-on-rails)
   - [RubyGems](https://rubygems.org/gems/react_on_rails)
   - [GitHub releases](https://github.com/shakacode/react_on_rails/releases)

2. If the changelog was updated before release (recommended), verify the GitHub release was auto-created with the correct notes.

3. For a prerelease or historical release that predates the stable changelog gate, if the changelog was NOT
   updated before release, update it now. Current stable releases cannot reach this state because they abort
   before publication:

   **Option A - Use Claude Code (recommended):**

   Run `$update-changelog 16.5.0` (using the already-released version) to analyze
   commits, write entries, and automatically open a PR. Use
   `$react-on-rails-update-changelog` instead when the catch-up PR must target
   `release/X.Y.Z`. After the PR merges, preview the GitHub release update. Keep
   `sync_github_release` preview-only; if the matching published release needs a live
   idempotent GitHub update, resume through `script/release VERSION` under its existing
   fenced lease as documented in
   [Partial-publication recovery](release-train-runbook.md#partial-publication-recovery):

   ```bash
   git pull --rebase
   bundle exec rake "sync_github_release[16.5.0,true]"
   ```

   **Option B - Manual (headers only, you must write entries):**

   ```bash
   bundle exec rake "update_changelog[16.5.0]"
   # Write entries manually, then preview the GitHub release update:
   bundle exec rake "sync_github_release[16.5.0,true]"
   ```

### Syncing GitHub Releases Manually

If the automatic GitHub release creation was skipped (e.g., CHANGELOG.md section was missing during release),
preview the recovery after updating the changelog. Direct live `sync_github_release` remains refused;
the fenced recovery path is `script/release VERSION`, as documented in
[Partial-publication recovery](release-train-runbook.md#partial-publication-recovery):

1. Update `CHANGELOG.md` with the published version section
2. Commit and push `CHANGELOG.md`
3. Run:

```bash
# Stable
bundle exec rake "sync_github_release[16.5.0,true]"

# Prerelease
bundle exec rake "sync_github_release[16.5.0.rc.1,true]"
```

`sync_github_release` reads release notes from the matching `CHANGELOG.md` section, applies the same size preparation
as the main release task, and creates or updates the GitHub release for the corresponding tag. It is the idempotent
recovery behavior when package publication succeeded but the final GitHub step failed. Preview it directly; for a
live create or edit, `script/release VERSION` supplies the required supervised per-write fence.

### Pre-Release Checklist

Before running the release command, verify:

1. **GitHub CLI**: Run `gh auth login` and ensure your account/token has write access to the repository (required for automatic GitHub release creation)

2. **NPM authentication**: Run `npm whoami` to confirm you're logged in
   - If not logged in, the release script will automatically run `npm login` for you

3. **RubyGems authentication**: Ensure you have valid credentials for `gem push`

4. **No uncommitted changes**: Run `git status` to verify clean working tree

### Two-Factor Authentication

You'll need to enter OTP tokens when prompted:

- Once for publishing `react-on-rails` to NPM (reused for subsequent NPM packages if valid)
- Once for publishing `react_on_rails` to RubyGems (reused for `react_on_rails_pro` if valid)

npm retries are classified from captured, sanitized output. Only an explicit npm OTP challenge prompts for a fresh
OTP. A transient network or registry-service failure retries with the same OTP and bounded exponential backoff.
Authentication failures such as `E401`/`ENEEDAUTH`, local lifecycle/build failures, registry rejections, and unknown
failures stop immediately without an OTP prompt. OTP values are redacted from raised diagnostics.

## Requirements

### NPM Publishing

You must be logged in and have publish permissions:

**For public packages (npmjs.org):**

```bash
npm login
```

### RubyGems Publishing

**For public gem (rubygems.org):**

- Standard RubyGems credentials via `gem push`

### Ruby Version Management

The script automatically detects and switches Ruby versions when needed:

- Supports: RVM, rbenv, asdf
- Set via `RUBY_VERSION_MANAGER` environment variable (default: `rvm`)
- Example: Pro dummy app requires Ruby 3.3.7, script auto-switches from 3.3.0

### Dependencies

This task depends on the `gem-release` Ruby gem, which is installed via `bundle install`.

## Testing with Dry Run

Before releasing to production, always preview with a dry run:

```bash
bundle exec rake "release[16.5.0,true]"
```

This uses a temporary git worktree to show exactly what would be updated without making any changes.

## Troubleshooting

### Dry Run First

Always test with a dry run before actually releasing:

```bash
bundle exec rake "release[16.2.0,true]"
```

This shows you exactly what would be updated without making any changes.

### NPM Authentication Issues

If you see errors like "Access token expired" or "E404 Not Found" during NPM publish:

1. Your NPM token has expired (tokens now expire after 90 days)
2. Run `npm login` to refresh your credentials
3. Retry the release

The release script now checks NPM authentication at the start and will automatically run `npm login` if needed, so this issue will be caught and handled before any changes are made.

### NPM Release Readiness Issues

If the release reports a pnpm version mismatch, first activate the exact pnpm version declared by the root
`packageManager`. Then run the exact frozen-install repair command it prints from the repository root for the
installed dependency check:

```bash
pnpm install --frozen-lockfile
```

Then fix any remaining build error and rerun the same explicit release version. The release will not have reached
release-checkout creation, pull/authentication, remote CI/tag/version reads, confirmation, version mutation,
ShakaPerf dispatch, tagging, publication, or OTP prompting.

During npm publication, only explicit transient diagnostics are retried with bounded backoff and the same OTP:
network codes such as `ECONNRESET`, npm/pnpm codes such as `E429`, `E503`, or `ERR_PNPM_FETCH_503`, and HTTP or
response/status-code contexts such as `HTTP 429` or `status code 503`. Successful `prepublishOnly`, `tsc`, or TypeScript
banner lines do not override a real transient diagnostic elsewhere in the output. Deterministic lifecycle codes and
tool/lifecycle lines containing `failed`, `failure`, `not found`, `not recognized`, or `error TS...` remain local hard
failures even when the same output also mentions a transient code. Bare numbers such as `429` or `500`, package sizes,
successful tool banners without a transient diagnostic, registry rejections, authentication failures, and unknown
output fail immediately. Only an explicit OTP challenge (`EOTP` or an equivalent one-time-password prompt) requests
a fresh code; all printed OTP values remain redacted.

### If Release Fails

If the release fails partway through (e.g., during NPM publish):

1. Stop the compound helper and keep the release-line lease. Do not delete or move tags, rewrite the
   release branch, rerun publication, or manually publish missing packages.
2. Check what was published with read-only registry queries:
   - NPM: `npm view react-on-rails@X.Y.Z`
   - RubyGems: `gem list react_on_rails -r -a`
3. Record the exact branch tip, local and remote tag identity, published artifact set, and helper output.
4. Follow [Partial-publication recovery](release-train-runbook.md#partial-publication-recovery). Resume only through
   `script/release VERSION` after the required claim, supervisor, and artifact evidence are all exact; if lease state
   or any remote/artifact identity is `UNKNOWN`, remain stopped.

## Version History

A dry-run preview with `bundle exec rake "release[X.Y.Z,true]"` shows the generated commit, which looks
like this:

```
commit abc123...
Author: Your Name <your.email@example.com>
Date:   Mon Jan 1 12:00:00 2024 -0500

    Bump version to 16.2.0

diff --git a/react_on_rails/lib/react_on_rails/version.rb b/react_on_rails/lib/react_on_rails/version.rb
index 1234567..abcdefg 100644
--- a/react_on_rails/lib/react_on_rails/version.rb
+++ b/react_on_rails/lib/react_on_rails/version.rb
@@ -1,3 +1,3 @@
 module ReactOnRails
-  VERSION = "16.1.1"
+  VERSION = "16.2.0"
 end

diff --git a/package.json b/package.json
index 2345678..bcdefgh 100644
--- a/package.json
+++ b/package.json
@@ -1,6 +1,6 @@
 {
   "name": "react-on-rails-workspace",
-  "version": "16.1.1",
+  "version": "16.2.0",
   ...
}
```
