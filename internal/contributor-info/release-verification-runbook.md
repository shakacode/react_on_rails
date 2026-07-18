# Release Verification Runbook (Behavioral Lanes)

Behavioral verification for a release candidate: the failure modes that unit CI, static review,
and the [`rc-testing-plan.md`](rc-testing-plan.md) fleet smoke gates are structurally blind to —
broken upgrade paths, debut-feature edge cases, resource leaks under sustained load, and
published-artifact defects.

This runbook complements, and does not replace, the canonical gates:

- [`rc-testing-plan.md`](rc-testing-plan.md) — hard-gate model, fleet bump PRs, tracking-issue
  lifecycle, report template, waivers. Lane reports from this runbook are posted to the same RC
  tracking issue.
- [`release-train-runbook.md`](release-train-runbook.md) — branch/tag mechanics. These lanes run
  during step 2 (stabilize) and must satisfy this runbook's gating rules before step 4 (promote).

Each lane below is a **self-contained agent prompt**: fill the parameters, paste the prompt into a
fresh agent session (Claude or Codex) with repo access, and collect the report. Run Lane 0 first.
After its inventory is complete, Lanes 1–3 and 4b are independent and can run in parallel; run the
final Lane 4a audit after issue-producing lanes and required fixes/waivers finish. Origin:
post–2026-06-12 review retro
([#4346](https://github.com/shakacode/react_on_rails/issues/4346)), where diff review found the
bugs it could find and these lanes cover what it could not.

## Parameters

Fill once per RC; every prompt references these placeholders. Lanes 2 and 4 add feature/version
placeholders sourced from the Lane 0 report. Lane 3's leak-shaped issue list is sourced from current
release review, audit, or tracking-issue findings; use `none` when there are no current leak-shaped
findings.

| Placeholder              | Meaning                                                                                                          | Example (17.0.0)                         |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| `{{PREV_STABLE}}`        | Last stable git tag (upgrade baseline)                                                                           | `v16.6.0`                                |
| `{{RC_TAG}}`             | RC under verification                                                                                            | `v17.0.0.rc.7`                           |
| `{{RELEASE_REF}}`        | Published tag under verification (`{{RC_TAG}}` for RC runs, final tag for final runs)                            | `v17.0.0.rc.7`                           |
| `{{FINAL_VERSION}}`      | Stable release target this RC gates                                                                              | `17.0.0`                                 |
| `{{TARGET_GEM_VERSION}}` | RubyGems version under test                                                                                      | `17.0.0.rc.7`                            |
| `{{TARGET_NPM_VERSION}}` | npm package version under test                                                                                   | `17.0.0-rc.7`                            |
| `{{RELEASE_BRANCH}}`     | Ephemeral release branch                                                                                         | `release/17.0.0`                         |
| `{{TRACKING_ISSUE}}`     | RC tracking issue (per rc-testing-plan lifecycle)                                                                | —                                        |
| `{{UPGRADE_APP_OSS}}`    | Fleet app on `{{PREV_STABLE}}` for the OSS upgrade dry-run                                                       | `shakacode/react-webpack-rails-tutorial` |
| `{{UPGRADE_APP_PRO}}`    | Flagship fleet app with Pro + RSC/streaming for the Pro upgrade dry-run                                          | `shakacode/react-on-rails-demo-flagship` |
| `{{RSC_VERSION}}`        | react-on-rails-rsc version this release line pins                                                                | `19.2.1`                                 |
| `{{LEAK_SHAPED_ISSUES}}` | Current release review/audit findings that look like memory, handle, or resource leak risks; use `none` if empty | `#4312`, `#4313`                         |

Re-run policy: a new RC with runtime changes refreshes Lane 0 first, then re-runs Lanes 2–4 for the
affected surfaces and Lane 1 if upgrade-relevant files changed (generators, install templates,
config, docs/upgrade). A version/changelog-metadata-only RC or final promotion re-runs Lane 4a plus
the Lane 4b version/coherence subset for the newly published artifacts and tag.

## Demo Fleet Release-Track Prompt

Use this prompt to update the demo fleet for an RC or final release. It complements
[`rc-testing-plan.md`](rc-testing-plan.md): hard-gate repos from
[`demo-fleet.yml`](demo-fleet.yml) block final release readiness, while soft-track repos are
inspected and filed as follow-up unless a maintainer explicitly promotes them.

For a coordinated candidate run, prefer the repo-local `$run-fleet-validation` lifecycle pack.
That pack owns candidate snapshotting, the release-wide preflight barrier, complete hard/soft
inventory, capability and baseline probes, the public-safe result ledger, independent audit,
authorized merge, default reachability/tree parity, and tracker-matrix rendering. The long-form
prompt below remains the behavioral depth contract and a manual fallback; its evidence must still
land in the generated ledger before closeout.

The ledger binds each hard-gate check to an immutable audited/reviewed/current target revision,
normalizes product gem/npm versions to the selected candidate, retains replayable independent-audit
evidence, and records merge/reachability proof per mutable target. Its derived aggregate therefore
represents partial fleet merges without discarding proof for lanes that already landed.

A failed required release path closes as `BLOCKED` with lane evidence and an owned blocker reference;
it must never be relabeled as passed or waived merely to satisfy closeout. Waived and deferred
blockers require structured authority, evidence URL, and reason fields in addition to any durable
owner.

An owned release-wide preflight defect may also close the candidate as `BLOCKED` without fabricating
an app run. Keep `APP_WORK_ALLOWED` false, retain the preflight blocker ID and public-safe evidence,
leave every app target untouched, record no maker identities in the independent audit, and mark
aggregate merge/reachability plus tracker promotion `blocked` (not merely `hold`). Report-only
targets that do run must retain their inspected package versions/sources and terminal exact-head
check evidence; their observed locks need not match the candidate snapshot. Candidate matching
applies only to candidate-managed packages on hard gates, including the separately resolved RSC
package, not independently versioned Shakapacker or Control Plane Flow dependencies.
Untouched app rows may retain read-only package-lock probes, and the validation-only generator gate
must bind its revision and check evidence to the pack's exact candidate commit.

This candidate-scoped orchestration does not replace standing fleet-health/currency automation,
which detects drift between releases. Hosted-CI dispatch and generator-CI routing improvements are
also dependencies, not substitutes: they shorten individual gates but do not own blocker
identities, combined audit, merge authority, or promotion closeout.

```text
You are updating the React on Rails demo fleet for {{RELEASE_REF}}.

Work from a clean checkout of `shakacode/react_on_rails`. Run `git fetch --prune origin main
--tags`, then check out `{{RELEASE_REF}}` before deriving feature coverage or demo work. For an RC
run where `{{RELEASE_REF}}` is `{{RC_TAG}}` and the tag is not published yet, confirm
`{{RELEASE_BRANCH}}` still exists with `git ls-remote --exit-code --heads origin
{{RELEASE_BRANCH}}`, fetch it with `git fetch --prune origin
{{RELEASE_BRANCH}}:refs/remotes/origin/{{RELEASE_BRANCH}}`, check out `origin/{{RELEASE_BRANCH}}`,
verify the version files match the target versions below, and record that the tag is not yet
available. For a final run, do not fall back to the release branch; stop and report if the final tag
is missing.

First read `AGENTS.md`, `internal/contributor-info/demo-fleet.yml`,
`internal/contributor-info/rc-testing-plan.md`,
`internal/contributor-info/release-verification-runbook.md`, and `CHANGELOG.md`. If
`internal/contributor-info/demo-fleet-design.md` exists, read it as historical design context only;
do not block the fleet update if that draft design file has already been removed. Run
`.agents/bin/agent-workflow-seam-doctor` before relying on repo workflow policy. If API tokens
appear missing, follow `AGENTS.md` for any trusted, session-provided token-loading helper; do not run
arbitrary `PATH` matches or unreviewed scripts.

Target versions:
- Release ref under verification: `{{RELEASE_REF}}`
- RC tag under verification: `{{RC_TAG}}`
- Final release target: `{{FINAL_VERSION}}`
- Expected gem version: `{{TARGET_GEM_VERSION}}`
- Expected npm package version: `{{TARGET_NPM_VERSION}}`
- Release tracker: `{{TRACKING_ISSUE}}`
- Verify the actual published/tagged artifacts before bumping demo repos.
- Use `{{RSC_VERSION}}` as the release-manager-supplied `react-on-rails-rsc` line. If release
  plans, manifests, or published artifacts disagree with `{{RSC_VERSION}}`, stop and report the
  mismatch instead of choosing a different RSC package line.

Goal:
Update every relevant demo, starter, flagship, and hard-gate app in `demo-fleet.yml` so it is
either tested against `{{RELEASE_REF}}` or explicitly recorded as soft-track/shelved with a reason. For
each app, account for user-visible React on Rails features added since that app's last
deployed/bumped baseline. If you detect bugs, release blockers, docs gaps, or demo-fleet metadata
gaps, file issues in `shakacode/react_on_rails`.

Repos:
- Prioritize every `hard_gate` repo first; hard-gate failures block final release readiness.
- Then inspect every `soft_track` repo; do not let soft-track failures block final unless a
  maintainer promotes that repo.
- Keep an owned blocker referenced exclusively by soft tracks as non-gating `PARTIAL` follow-up.
  The same blocker is release-gating if preflight, a hard gate, or a required path also references it.
- Treat `shakacode/hichee` and Pro details as private: public tracker comments may say
  install/build/smoke/CI passed or failed, but must not expose private logs, URLs, screenshots,
  customer data, secrets, or proprietary Pro source details.

For each repo:
1. Determine the baseline actually under test:
   - Prefer the last deployed commit/version if discoverable from deployment metadata, GitHub
     environments, release tags, CPFlow, or repo docs.
   - If deployment state is not discoverable, use the current default branch lockfiles as the
     baseline and mark last-deployed as `UNKNOWN`.
2. Compare baseline package versions to `{{TARGET_GEM_VERSION}}` and `{{TARGET_NPM_VERSION}}`.
3. Bump only packages the manifest says the repo consumes, plus required coupled packages/peers
   needed for a coherent install.
4. Use the repo's declared package manager from `demo-fleet.yml`; update lockfiles consistently.
5. Inspect the app's actual features and add/update demo coverage for relevant new behavior from
   this release. Use the CHANGELOG and release diff as authority. Consider, where applicable:
   - Pro/RSC React and `react-on-rails-rsc` line adoption
   - provider-backed RSC prefetch
   - buffered/static/cached RSC helpers, cache tags, and revalidation
   - streamed RSC observability marks and `Server-Timing`
   - typed response type generation and `createRailsAction`
   - create-app/generator behavior, hidden Redux path, and `bin/dev clean`
   - RSC doctor diagnostics, hydration/getStore fixes, RSC error recovery, cache read fixes,
     renderer shutdown, asset filename validation, and sensitive-props error redaction
6. Do not force irrelevant features into a demo. Record why the feature is not applicable and, if
   that leaves an intended fleet coverage gap, file or update a `react_on_rails` issue.
7. Run local validation before pushing:
   - package install
   - `bundle install` where applicable
   - manifest `ruby_test`
   - manifest `js_test` if non-null
   - manifest `build`
   - smoke paths from the manifest, including browser console checks where practical
8. Open or update a PR in the demo repo with:
   - target versions
   - feature coverage added/verified
   - exact commands run and results
   - known unrelated failures, with issue links
9. If `demo-fleet.yml` metadata is wrong after inspection, open a separate `react_on_rails` PR
   updating package manager, commands, smoke paths, review-app data, or `verify` state.

Tracking and issues:
- Find or create the release tracker: `{{TRACKING_ISSUE}}`.
- Add a section for `{{RC_TAG}}` linking every hard-gate PR and evidence.
- Before filing issues, confirm labels exist: the concrete `release:<X.Y.Z>-must-have` label
  derived from `{{FINAL_VERSION}}` (for example, `release:17.0.0-must-have` when
  `{{FINAL_VERSION}}` is `17.0.0`), `P2`, and `documentation`.
- File every suspected RC regression, release blocker, docs gap, missing feature coverage, or
  manifest/orchestrator gap in `shakacode/react_on_rails`.
- Use the concrete release must-have label for anything that would block or seriously mislead a
  real RC/final upgrader; otherwise use the normal priority/docs labels.
- If a failure is clearly demo-local, still record it in the release tracker and file/link the
  appropriate issue; do not silently waive it.

Final report:
Return a compact matrix with columns: `repo`, `tier`, `baseline`, `target`, `PR`,
`new features accounted for`, `validation`, `issues filed`, `release impact`.

End with:
- hard-gate pass/block summary
- soft-track follow-ups
- all `react_on_rails` issues created
- any public-safe private-app notes
- final recommendation: `ready`, `blocked`, or `ready with explicit waivers`
```

## Lane 0 — Release inventory (feeds Lanes 2 and 4)

Cheap, run first. Produces the debut-feature list and breaking-change list the other lanes consume.

**Prompt:**

```text
You are preparing the verification inventory for react_on_rails {{RC_TAG}} (previous stable
{{PREV_STABLE}}). Work in a clean checkout of shakacode/react_on_rails at {{RC_TAG}}. Read-only.

1. Compute the release diff: `git log --oneline {{PREV_STABLE}}..{{RC_TAG}}`, then use
   `git diff --stat {{PREV_STABLE}} {{RC_TAG}} -- <shipping paths>` to navigate and
   `git diff {{PREV_STABLE}} {{RC_TAG}} -- <shipping paths>` or targeted file reads to inspect
   actual hunks before deriving the inventory. Replace `<shipping paths>` with:
   react_on_rails/lib, react_on_rails/app, react_on_rails/sig, react_on_rails_pro/lib,
   react_on_rails_pro/app, react_on_rails_pro/sig, packages/react-on-rails/src,
   packages/react-on-rails-pro/src,
   packages/react-on-rails-pro-node-renderer/src, packages/create-react-on-rails-app/src,
   packages/create-react-on-rails-app/bin, generator templates, package.json manifests, gemspecs,
   and version files.
2. Read the CHANGELOG.md sections covering {{PREV_STABLE}}..{{RC_TAG}}.
3. Produce three lists, each entry with PRs, files, and doc links:
   a. DEBUT FEATURES — user-facing capabilities new in this release (new APIs, options,
      helpers, generator behavior, protocol changes). For each: the contract as documented,
      the surfaces it touches (Ruby / npm / renderer / generated app), and its opt-in state
      (default-on vs flag/config-gated).
   b. BREAKING CHANGES — anything that changes behavior for an app upgrading from
      {{PREV_STABLE}}, whether or not the CHANGELOG labels it breaking. Derive from the diff,
      not only from the CHANGELOG (removed/renamed public methods, changed defaults, raised
      minimums, changed generated output).
   c. DEPENDENCY LINE CHANGES — runtime dependency lines that moved (e.g. react-on-rails-rsc,
      React peer ranges, Node/Ruby minimums).
4. Flag any item in (b) that is absent from the CHANGELOG — these become Lane 4a findings.

Output: a single markdown report with the three lists, ranked by user impact. No prose padding.
This report is pasted into the Lane 2 and Lane 4a prompts, so keep entries self-contained.
```

**Pass criteria:** none (inventory). Post the report to `{{TRACKING_ISSUE}}`.

## Lane 1 — Migration-guide-driven upgrade dry-run

Distinct from the fleet RC bump PRs in rc-testing-plan.md: those bump apps already tracking the RC
line. This lane starts from **`{{PREV_STABLE}}` and follows the published upgrade documentation
verbatim** — it verifies the docs as much as the code, and it is the closest simulation of what
every real user does on release day. Run for every major, and for minors that touch generators,
config, or install templates.

**Prompt (run once per app: `{{UPGRADE_APP_OSS}}`, then `{{UPGRADE_APP_PRO}}`):**

```text
You are performing a release-day upgrade rehearsal for react_on_rails {{RC_TAG}}.

Setup: clone the app for this run (`{{UPGRADE_APP_OSS}}` or `{{UPGRADE_APP_PRO}}`, matching the
invocation above) at its current default branch into a scratch worktree; confirm it is on the
{{PREV_STABLE}} line (Gemfile.lock + package.json). If it is not, check out the last commit that was.
Do not push anything to the app repo.

Rules of the rehearsal:
- Follow the published upgrade documentation VERBATIM (docs upgrade guide for this major, the
  CHANGELOG breaking-changes section, and README install notes). Execute exactly what the docs
  say, in order.
- Every time you must do something the docs did not tell you — a missing step, a wrong command,
  an unmentioned config change, an error you had to solve by reading source — STOP, record it as
  a DOCS GAP with the exact error text and the fix you applied, then continue.
- Do not silently modernize unrelated app code. If the app needs an unrelated fix to proceed,
  record it as APP DEBT and apply the minimum.

Verification ladder (record evidence at each rung):
1. bundle install / package install succeed with the RC versions.
2. App boots in development; server-rendered and client-rendered pages respond.
3. Production build (assets:precompile or the app's build command) succeeds.
4. The app's own test suite passes (or fails only on pre-existing failures — verify by running it
   once on {{PREV_STABLE}} first).
5. Smoke the app's primary routes (per the demo-fleet.yml smoke list if this app is in the fleet):
   SSR HTML present, hydration completes without console errors, and for the Pro app: streaming
   renders, RSC routes, and (if enabled) pull-mode props work.

Output: a report with (a) verdict PASS / FAIL / PASS-WITH-GAPS, (b) the DOCS GAP list — this is
the primary deliverable; each gap becomes a docs issue before final, (c) APP DEBT list, (d) the
upgrade diff evidence (full diff for public apps; redacted diff summary for Pro/private apps, with
private logs, URLs, screenshots, app details, and proprietary hunks omitted), (e) evidence per
ladder rung (commands + key output). File each DOCS GAP in `shakacode/react_on_rails`, for example
with `gh issue create --repo shakacode/react_on_rails`, labeled `release:<X.Y.Z>-must-have` if it
would strand a real upgrader, else with both `P2` and `documentation`.
```

**Pass criteria:** ladder rungs 1–5 pass on both apps; every DOCS GAP filed. A FAIL on any rung
that a real user would hit blocks promotion for majors, and for in-scope minors when the failure
touches the changed generator/config/install-template surface; unrelated minor failures must be
filed and waived under the rc-testing-plan process.

## Lane 2 — Debut-feature abuse pass

Adversarial behavioral testing of what is new in this release. New features have had the least
soak time, and the highest-severity review findings historically cluster where a new feature
interacts with an old mechanism. Input: Lane 0's DEBUT FEATURES list.

**Prompt (run once per debut feature; parallelize across features):**

```text
You are adversarially testing one debut feature of react_on_rails {{RC_TAG}}:

FEATURE: {{FEATURE_NAME}} — {{ONE_LINE_CONTRACT}}
DOCS: {{DOC_LINKS}}   PRS: {{PR_LINKS}}   SURFACES: {{SURFACES}}

Work in the react_on_rails monorepo at {{RC_TAG}}; use react_on_rails_pro/spec/dummy (or
react_on_rails/spec/dummy for OSS-only features) as the running app unless SURFACES includes CLI,
generator, generated app, or install-template behavior. For those generator-owned surfaces, create a
scratch app with the packed create-react-on-rails-app or the relevant generator output and test the
generated defaults/files directly. Use a scratch worktree or throwaway branch for test pages/specs; do
not push, open a PR, or merge anything from this session.

Method:
1. Enumerate the documented contract: inputs, outputs, defaults, error behavior, config gates.
2. Derive an abuse matrix — at minimum:
   - Invalid/boundary inputs: nil/empty/huge/wrong-type for every new option or prop.
   - Lifecycle abuse: disconnect mid-stream, navigate away mid-hydration, unmount/remount loops,
     double initialization, Turbo navigation with the feature active.
   - Concurrency: many simultaneous renders/streams using the feature; interleaving with
     caching/prerender if applicable.
   - Degraded dependencies: the feature's optional deps absent or erroring (cache store down,
     renderer restarting, RSC bundle missing) — the failure should be diagnosable, never silent.
   - Interaction sweep: run the feature against each OTHER debut feature it can co-occur with.
3. Execute the matrix. For every defect: minimal repro, severity, exact file:line hypothesis if
   you can trace it. Distinguish BROKEN (contract violated) from UNDOCUMENTED (behavior
   surprising but arguably intended) from NOISE.
4. For each confirmed BROKEN finding, write the repro as a permanent regression spec/e2e test in
   the style of react_on_rails_pro/spec/dummy/e2e-tests/rsc_fouc.spec.ts and include it in the
   report as a patch — release gates should accrete from RC findings.

Output: verdict per feature (SOLID / DEFECTS-FOUND), the defect list with repros, the patch with
permanent regression tests, and the abuse matrix with pass/fail per cell so coverage is explicit.
File BROKEN findings as issues labeled release:<X.Y.Z>-must-have (contract violations in a debut
feature ship as day-one bugs otherwise).
```

**Pass criteria:** every debut feature SOLID, or its BROKEN findings fixed or explicitly waived
under the rc-testing-plan waiver rules before promotion. Confirmed-defect repros land as permanent
tests.

## Lane 3 — Stress and soak

Sustained-load behavior: memory growth, leaked handles, degradation over time. Review can flag
leak-shaped code; only a soak run proves or disproves it. Uses the repo's `stress-test` skill,
which orchestrates the destructive demo-workspace QA lane (leakage, memory, performance, hostile
inputs, fault injection) against repo-owned apps.

**Prompt:**

```text
Work in a clean shakacode/react_on_rails checkout at {{RC_TAG}}; the stress-test skill packs
artifacts from the currently checked-out framework repo. Resolve the release tags to commit SHAs
first: `PREV_SHA=$(git rev-parse {{PREV_STABLE}}^{commit})` and
`RC_SHA=$(git rev-parse {{RC_TAG}}^{commit})`. Invoke the stress-test skill against the
react_on_rails {{RC_TAG}} release diff with:
`--from $PREV_SHA --to $RC_SHA --tier deep --max-hours 8`
(or the narrower PR/commit range if this RC is a focused rerun). The skill builds
packed gem/npm artifacts into its own `tmp/stress-test-<timestamp>/` workspace and creates demo
apps there; do not point it at `react_on_rails_pro/spec/dummy` or edit tracked app/spec files. This
is an authorized destructive QA run on repo-owned demo workspaces only. Stay attached through the
skill's Phase 0 plan and type `go` only after the printed scope/cost plan is acceptable; it will not
proceed unattended before that confirmation gate.

Focus areas for this release, in priority order:
1. Sustained streamed-RSC + incremental-render traffic (hours, not minutes): renderer worker RSS,
   Rails process RSS, open-connection counts. Watch specifically for the leak shapes flagged in
   this release's review: {{LEAK_SHAPED_ISSUES}}.
2. Client-side soak: repeated Turbo navigations across pages using the debut features; browser
   heap growth per 100 navigations; listener/observer counts.
3. Fault injection under load: kill/restart the node renderer mid-stream, drop client connections
   mid-render, exhaust the cache store — the system must degrade with diagnosable errors and
   recover without restart.
4. Hostile inputs on new protocol surfaces (oversized props, malformed control frames, absurd
   component counts) — server must reject cleanly, never hang or crash the worker pool.

Output: the skill's gated findings report plus a resource-over-time table (RSS/heap/connections
at t=0 and at 25%, 50%, 75%, and 100% of the actual run, including wall-clock timestamps). Verdict:
STABLE (flat resource curves, clean recovery) or findings with severity. File leaks/hangs as
issues; anything that requires a process restart to recover is release:<X.Y.Z>-must-have.
```

**Pass criteria:** STABLE verdict, or every non-flat curve explained and its issue triaged. A
leak that accumulates under normal traffic blocks promotion.

## Lane 4 — Mechanical audits

### 4a. Changelog and migration-guide completeness

**Prompt:**

```text
Audit release-notes completeness for react_on_rails {{RC_TAG}} against the real release diff.
Inputs: Lane 0's BREAKING CHANGES and DEBUT FEATURES lists; the repo at {{RC_TAG}}. Use the
repo-local react-on-rails-update-changelog skill for release-branch/RC changelog work, and
post-merge-audit where it fits; this prompt is the acceptance bar.

Check, with file/PR evidence for every claim:
1. Every Lane 0 BREAKING CHANGE appears in the CHANGELOG release section AND in the upgrade
   guide, with the user-visible consequence stated (not just the internal change).
2. Every DEBUT FEATURE has a CHANGELOG entry and documentation reachable from the docs site nav.
3. Every issue labeled release:<X.Y.Z>-must-have has a promotion-safe disposition. For a code or
   docs defect, verify its fix is in `{{PREV_STABLE}}..{{RC_TAG}}` by commit; an open issue with a
   landed fix is not automatically a gap, but stale acceptance criteria or remaining work is. For
   a final-assembly/publish issue whose own lifecycle necessarily ends after promotion, require
   its pre-publish dependencies and checklist to be satisfied; do not require the issue to close
   before the publish steps it tracks can run. Example: an unchecked issue box is stale only when
   linked commit evidence proves the tagged candidate already satisfies it and no implementation,
   documentation, test, or rollout work remains. An unchecked box naming any such remaining work is
   still a gap. A final-publish issue may remain open when its only remaining boxes are the publish
   steps that promotion itself unlocks.
4. Version-stamp coherence: derive the expected gem/CHANGELOG and npm package versions from
   {{RC_TAG}} before comparing (for example, `v17.0.0.rc.7` -> gem/CHANGELOG `17.0.0.rc.7`,
   npm `17.0.0-rc.7`); gem version.rb files, every published package.json, and the CHANGELOG
   heading match those normalized targets.
5. No CHANGELOG entry describes something the diff does not contain (stale/aspirational notes).

Output: a checklist table (item / status / evidence), the list of missing or wrong entries as
ready-to-apply CHANGELOG/docs patch hunks, and a verdict COMPLETE / GAPS. Gaps are cheap to fix —
open one PR carrying all patch hunks rather than issues.
```

### 4b. Published-artifact verification

Modeled on react_on_rails_rsc's `scripts/verify-release.sh` contract enforcement.

**Prompt:**

```text
Verify the publishable artifacts for react_on_rails {{RC_TAG}} before (or immediately after) npm/
gem publication. Work in the monorepo at {{RC_TAG}} with a clean install. Write all generated
tarballs, packed gems, and unpacked artifact trees under a scratch directory such as
`tmp/release-artifact-check-{{RC_TAG}}/`; do not leave `npm pack`/`gem build` outputs in tracked
package directories.

For each published npm package (react-on-rails, react-on-rails-pro,
react-on-rails-pro-node-renderer, create-react-on-rails-app):
1. Inspect the package exactly as it will be published. Before publication, replay the release
   publish preparation: run the package build/prepublish lifecycle that creates publishable files,
   then wrap local `npm pack` inspection in a throwaway helper that loads `rakelib/release.rake` and
   calls `with_publishable_package_json` so `workspace:*` dependencies are rewritten the same way
   `pnpm publish` rewrites them. Do not run the real non-dry-run release task just to get rewritten
   package.json files. After publication, inspect the actual npm metadata and packed tarball. The file
   list matches the package.json "files" globs plus npm's automatic inclusions such as package.json,
   README/LICENSE files, and main/bin targets; every entry-point/export map target exists in the
   tarball; no test/fixture/source-map junk ships; Pro packages carry the commercial license header
   where required (script/check-pro-license-headers).
2. Peer/dependency contract: for packages or generated manifests that own the react-on-rails-rsc
   dependency line, its peer/pin range includes {{RSC_VERSION}} and excludes known-bad versions of
   that line; packages that do not own RSC do not need to declare that peer. For artifacts or
   generated manifests that declare or generate react/react-dom dependencies, their peer/pin ranges
   match the supported matrix; generated RSC app manifests pin react/react-dom versions compatible
   with the {{RSC_VERSION}} support matrix rather than only matching the newest React line. Artifacts
   that do not declare or generate React dependencies do not need to add them for this check.
   For every npm package, compare the published runtime dependency contract against the release plan:
   `dependencies`, `optionalDependencies`, `peerDependencies`, `engines`, `bin`, `main`, and `exports`
   metadata are present and bounded as intended, including non-React contracts such as node-renderer
   runtime dependencies and create-app `engines.node`. workspace:* references in install-time
   dependency fields (`dependencies`, `optionalDependencies`, `peerDependencies`) are rewritten to
   real versions in the release-task-rewritten or published manifest.
3. Install the packed tarballs (not the workspace) into a scratch app skeleton and run
   `node script/check-single-react-resolution.mjs <scratch-app>` — one React installation,
   matching versions. For create-react-on-rails-app, also invoke the command installed from the
   packed tarball (for example `node_modules/.bin/create-react-on-rails-app --help` or the package's
   documented smoke mode) so the published shebang, executable bit, and wrapper imports are tested.
4. Gems: before publication, `gem build` both gemspecs from the tag; unpack and diff the file
   lists against the repo expectations. After publication, fetch the actual RubyGems artifacts for
   the normalized gem version, unpack those `.gem` files, and run the same file-list/version checks
   on the published artifacts. Inspect the built/fetched gem specifications as well: runtime
   dependencies, required Ruby version, and inter-gem version bounds match the release plan.
   version.rb values match the normalized tag.
5. Cross-artifact coherence: derive the expected gem version and npm version from {{RC_TAG}}
   before comparing (for example, `v17.0.0.rc.7` -> gem/CHANGELOG `17.0.0.rc.7`, npm
   `17.0.0-rc.7`). The normalized npm versions, gem versions, tag, and CHANGELOG heading agree;
   the rsc pin in packed manifests is {{RSC_VERSION}}. Published npm dist-tags point at those same
   normalized package versions: prereleases use the expected rc tag, final releases use latest, and
   any package missing or carrying the wrong dist-tag is a defect.

Output: per-artifact table (check / result / evidence), verdict CLEAN / DEFECTS. Artifact defects
are always release blockers — a wrong tarball cannot be waived, only republished.
```

**Pass criteria:** 4a COMPLETE (or its patch PR merged into the release branch); 4b CLEAN.

## Reporting and gating

- Post each lane's report as a comment on `{{TRACKING_ISSUE}}`, using the rc-testing-plan report
  conventions (versions, evidence, tester, date). One comment per lane per RC.
- Default blocking rules, subject to the rc-testing-plan waiver process:

| Lane                     | Blocks promotion when                                            |
| ------------------------ | ---------------------------------------------------------------- |
| 1 Upgrade dry-run        | Any ladder-rung FAIL a real upgrader would hit (hard for majors) |
| 2 Feature abuse pass     | Unfixed, unwaived BROKEN finding in a debut feature              |
| 3 Stress/soak            | Leak under normal traffic, or non-recoverable degradation        |
| 4a Changelog audit       | Any Lane 4a checklist item not COMPLETE                          |
| 4b Artifact verification | Any defect (cannot be waived, only republished)                  |
| 0 Inventory              | Never (input to the others)                                      |

- Before first issue filing, confirm the repo has `release:<X.Y.Z>-must-have`, `P2`, and
  `documentation` labels. Findings filed during lanes use the release must-have label for blockers
  and normal P-labels otherwise, matching the repo triage scheme.

## Appendix — instantiation for 17.0.0

Parameters: `{{PREV_STABLE}}`=`v16.6.0`, `{{RC_TAG}}`=`v17.0.0.rc.7`,
`{{RELEASE_REF}}`=`v17.0.0.rc.7` for the RC.7 demo-fleet run (use `v17.0.0` for the final promotion
run), `{{FINAL_VERSION}}`=`17.0.0`, `{{TARGET_GEM_VERSION}}`=`17.0.0.rc.7`,
`{{TARGET_NPM_VERSION}}`=`17.0.0-rc.7`, `{{RELEASE_BRANCH}}`=`release/17.0.0`,
`{{RSC_VERSION}}`=`19.2.1` (use `19.2.1-rc.0` only if stable publication is not
available; gated on
[react_on_rails_rsc#148](https://github.com/shakacode/react_on_rails_rsc/issues/148) and
[#4357](https://github.com/shakacode/react_on_rails/issues/4357)).

Lane 0 head start — known debut features for Lane 2 (verify/extend via the Lane 0 prompt):
bidirectional pull-mode async props (#4048), `hydrate_on` scheduling (#4037), `cache_tags`/
`revalidate_tag` (#3964), buffered RSC static-page helpers (#4268), typed Rails actions and
response-type generation (#3942/#4259/#4260), streamed-RSC observability marks and Server-Timing
(#4222/#4251), Tailwind layout-owned packs (#4182), Pro-default create-app (#4217/#4232), FOUC
stylesheet gating (#4047), RSC 19.2 line adoption (#4357).

Lane 2/4a must-verify-fixed list (from the post–June-12 review, umbrella #4346): `#4310`, `#4311`,
`#4314`, `#4316`, `#4326`, `#4340`, `#4342`, `#4357`, and `rsc#148` (via the {{RSC_VERSION}} bump).

Lane 3 `{{LEAK_SHAPED_ISSUES}}`: `#4312` (executionContext leak), `#4313` (source-map retention),
`#4328` (`hydrate_on: visible` detached nodes), `#4329` (performance-marks queue).
